import asyncio
from uuid import uuid4
import pytest
from sqlalchemy import select,func
from app.database.session import Session
from app.models.entities import Order,Outbox,OrderItem

BODY={'restaurant_id':'saffron','delivery_address':'10 Fictional Lake Road, Bengaluru','items':[{'menu_item_id':'saffron-1','quantity':2}]}
async def create(client,headers,body=None,key=None):
    return await client.post('/api/v1/orders',json=body or BODY,headers={**headers,'Idempotency-Key':key or str(uuid4())})

async def test_login_and_access(client,headers,admin_headers):
    assert (await client.post('/api/v1/auth/login',json={'email':'customer@quickbite.test','password':'wrong'})).status_code==401
    assert (await client.get('/api/v1/me')).status_code==401
    assert (await client.get('/api/v1/admin/summary',headers=headers)).status_code==403
    assert (await client.get('/api/v1/admin/summary',headers=admin_headers)).status_code==200
    assert (await create(client,admin_headers)).status_code==403

async def test_expired_token(client):
    import jwt
    from app.config.settings import settings
    cfg=settings()
    token=jwt.encode({'sub':'customer-demo','role':'CUSTOMER','exp':1,'iat':0,'jti':'test','iss':cfg.jwt_issuer,'aud':cfg.jwt_audience},cfg.jwt_secret,algorithm='HS256')
    assert (await client.get('/api/v1/me',headers={'Authorization':'Bearer '+token})).status_code==401

@pytest.mark.parametrize('change',[
 {'items':[{'menu_item_id':'missing','quantity':1}]},
 {'items':[{'menu_item_id':'saffron-1','quantity':0}]},
 {'items':[{'menu_item_id':'saffron-1','quantity':-1}]},
 {'items':[{'menu_item_id':'saffron-1','quantity':21}]},
 {'items':[{'menu_item_id':'saffron-1','quantity':1.0}]},
 {'items':[{'menu_item_id':'saffron-4','quantity':1}]},
 {'items':[{'menu_item_id':'saffron-1','quantity':1},{'menu_item_id':'ember-1','quantity':1}]},
 {'delivery_address':'bad'}, {'total_amount_minor':1}, {'customer_id':'admin-demo'},
])
async def test_invalid_input_is_atomic(client,headers,change):
    response=await create(client,headers,{**BODY,**change});assert response.status_code==422
    assert set(response.json())=={'code','message','details','request_id'}
    async with Session() as s:
        assert await s.scalar(select(func.count()).select_from(Order))==0
        assert await s.scalar(select(func.count()).select_from(Outbox))==0

async def test_server_price_and_replay(client,headers):
    key=str(uuid4());first=await create(client,headers,key=key);again=await create(client,headers,key=key)
    assert first.status_code==again.status_code==202
    assert first.json()==again.json()
    assert first.json()['total_amount_minor']==57800
    assert first.headers['location']==again.headers['location']
    different=await create(client,headers,{**BODY,'delivery_address':'11 Another Demo Road, Bengaluru'},key)
    assert different.status_code==409
    async with Session() as s:
        assert await s.scalar(select(func.count()).select_from(Order))==1
        assert await s.scalar(select(func.count()).select_from(Outbox))==1
        item=await s.scalar(select(OrderItem));assert item.unit_price_minor==28900

async def test_concurrent_identical_checkout(client,headers):
    key=str(uuid4());results=await asyncio.gather(*(create(client,headers,key=key) for _ in range(10)))
    assert all(r.status_code==202 for r in results)
    assert len({r.json()['order_id'] for r in results})==1
    async with Session() as s:assert await s.scalar(select(func.count()).select_from(Order))==1

async def test_ownership_404(client,headers,admin_headers):
    id=(await create(client,headers)).json()['order_id']
    token=(await client.post('/api/v1/auth/login',json={'email':'customer2@quickbite.test','password':'Customer@12345'})).json()['access_token']
    for suffix in ['', '/history','/notifications']:
        assert (await client.get('/api/v1/orders/'+id+suffix,headers={'Authorization':'Bearer '+token})).status_code==404
    assert (await client.get('/api/v1/orders/'+id,headers=admin_headers)).status_code==200

async def test_outbox_failure_rolls_back(client,headers,monkeypatch):
    from app.services import checkout
    def fail(*_):raise RuntimeError('injected before commit')
    monkeypatch.setattr(checkout,'enqueue',fail)
    assert (await create(client,headers)).status_code==503
    async with Session() as s:
        assert await s.scalar(select(func.count()).select_from(Order))==0
        assert await s.scalar(select(func.count()).select_from(Outbox))==0
