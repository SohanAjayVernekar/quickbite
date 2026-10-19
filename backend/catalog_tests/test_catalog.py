"""Focused catalogue regression tests. No PostgreSQL or RabbitMQ is required.

Run: python -m pip install aiosqlite pytest
     PYTHONPATH=backend python -m pytest backend/catalog_tests -q

SQLite checks cover catalog queries only, not payment/checkout integration.
"""
import asyncio
import os
from pathlib import Path
import pytest

os.environ.setdefault('APP_ENV','test')
os.environ.setdefault('DATABASE_URL','postgresql+asyncpg://unused:unused@127.0.0.1/quickbite_test')
os.environ.setdefault('AMQP_URL','amqp://guest:guest@127.0.0.1/')
os.environ.setdefault('JWT_SECRET','catalog-test-only-secret-more-than-32-characters')
os.environ.setdefault('RABBITMQ_PASSWORD','catalog-test-only')

from app.database.catalog import CATALOG


def test_catalog_size_integrity_and_dietary_flags():
    assert len(CATALOG) == len({k.id for k in CATALOG}) == len({k.name for k in CATALOG}) == 200
    assert len({k.cuisine for k in CATALOG}) == 20
    assert sum(len(k.menu) for k in CATALOG) == 2400
    for k in CATALOG:
        assert len(k.menu) == len({d.name for d in k.menu}) == 12
        assert 0 < k.rating <= 50 and k.eta > 0
        for d in k.menu:
            assert d.price > 0 and isinstance(d.price,int)
            assert len(d.name) <= 120 and d.description
            if any(word in d.name.lower() for word in ('chicken','fish','prawn','salmon','lamb','squid','omelette','egg breakfast','egg dosa','croissant')):
                assert not d.vegetarian, d.name
    assert sum(not d.vegetarian for k in CATALOG for d in k.menu) > 600
    original = {k.id:k for k in CATALOG}
    assert original['saffron'].menu[0].name == 'Paneer Dum Biryani'
    assert original['saffron'].menu[0].price == 28900
    assert not original['saffron'].menu[3].available


def test_all_local_food_assets_exist():
    assets = Path(__file__).resolve().parents[2] / 'frontend/assets/images'
    for k in CATALOG:
        for image in (k.image, *(d.image for d in k.menu)):
            assert image.startswith('emoji:') or (assets / image).is_file(), image
    assert (assets/'floating-feast.png').is_file()


def test_seed_and_authenticated_catalog_api(monkeypatch):
    """Exercise the real route functions, seed, SQL and response models in isolation."""
    asyncio.run(_api_checks(monkeypatch))

async def _api_checks(monkeypatch):
    import httpx
    from sqlalchemy import select,func
    from sqlalchemy.ext.asyncio import create_async_engine,async_sessionmaker
    from app.database import seed as seeder
    from app.api import routes
    from app.auth import security
    from app.main import app
    from app.models.entities import Base,User,Restaurant,MenuItem,Driver
    engine = create_async_engine('sqlite+aiosqlite:///:memory:')
    sessions = async_sessionmaker(engine,expire_on_commit=False)
    async with engine.begin() as c:
        await c.run_sync(lambda conn: Base.metadata.create_all(conn,tables=[User.__table__,Restaurant.__table__,MenuItem.__table__,Driver.__table__]))
    monkeypatch.setattr(seeder,'Session',sessions)
    # seed() disposes its ordinary engine when invoked as a command. Retain this test DB.
    class NoDispose:
        async def dispose(self): pass
    monkeypatch.setattr(seeder,'engine',NoDispose())
    monkeypatch.setattr(routes,'Session',sessions)
    monkeypatch.setattr(security,'Session',sessions)
    await seeder.seed()
    async with sessions() as s,s.begin():
        item = await s.get(MenuItem,'saffron-1'); item.price_minor = 30100
        restaurant = await s.get(Restaurant,'saffron'); restaurant.description = 'Owner edited text'
    await seeder.seed()
    async with sessions() as s:
        assert await s.scalar(select(func.count()).select_from(Restaurant)) == 200
        assert await s.scalar(select(func.count()).select_from(MenuItem)) == 2400
        assert (await s.get(MenuItem,'saffron-1')).price_minor == 30100
        assert (await s.get(Restaurant,'saffron')).description == 'Owner edited text'
    async with httpx.AsyncClient(transport=httpx.ASGITransport(app=app),base_url='http://test') as client:
        assert (await client.get('/api/v1/restaurants')).status_code == 401
        public = (await client.get('/api/v1/public/catalog')).json()
        assert public['total_restaurants'] == 200 and len(public['cuisines']) == 20
        assert len({d['restaurant_id'] for d in public['dishes']}) == 8
        token = (await client.post('/api/v1/auth/login',json={'email':'customer@quickbite.test','password':'Customer@12345'})).json()['access_token']
        headers={'Authorization':'Bearer '+token}
        async def get(path):
            r = await client.get('/api/v1'+path,headers=headers)
            assert r.status_code == 200,r.text
            return r.json()
        seen=set()
        for page in range(1,18):
            result = await get(f'/restaurants?page={page}&page_size=12')
            ids={r['id'] for r in result['items']}
            assert not seen.intersection(ids)
            seen.update(ids)
            assert result['total']==200
        assert len(seen)==200
        assert not (await get('/restaurants?page=18&page_size=12'))['items']
        filtered=await get('/restaurants?cuisine=Japanese&vegetarian=true&min_rating=45')
        assert filtered['total'] > 0
        assert all(r['cuisine']=='Japanese' and r['rating_tenths']>=45 for r in filtered['items'])
        search=await get('/restaurants?q=quinoa')
        assert search['total']>0 and all(r['cuisine']=='Healthy' for r in search['items'])
        assert (await get('/restaurants?q=%25'))['total']==0
        assert (await get('/restaurants?q=there-is-no-such-dish'))['total']==0
        fastest=await get('/restaurants?sort=fastest&page_size=100')
        assert [r['eta_minutes'] for r in fastest['items']]==sorted(r['eta_minutes'] for r in fastest['items'])
        names=await get('/restaurants?sort=name&page_size=100')
        assert [r['name'] for r in names['items']]==sorted(r['name'] for r in names['items'])
        mixed=await get('/restaurants/kitchen-001/menu')
        assert mixed['total']==12 and any(not d['vegetarian'] for d in mixed['items'])
        veg=await get('/restaurants/kitchen-001/menu?vegetarian=true')
        assert 0 < veg['total'] < mixed['total'] and all(d['vegetarian'] for d in veg['items'])
        assert (await client.get('/api/v1/restaurants?sort=invalid',headers=headers)).status_code==422
        assert (await client.get('/api/v1/restaurants/missing/menu',headers=headers)).status_code==404
    await engine.dispose()
