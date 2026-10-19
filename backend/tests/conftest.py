"""Integration tests require isolated real services; never point these at application data."""
import os
from urllib.parse import urlsplit
import pytest_asyncio
import httpx
from sqlalchemy import text
url=os.getenv('TEST_DATABASE_URL','')
if urlsplit(url).path!='/quickbite_test':
    raise RuntimeError('Set TEST_DATABASE_URL to an isolated PostgreSQL database named quickbite_test.')
os.environ.update(DATABASE_URL=url,AMQP_URL=os.environ['TEST_AMQP_URL'],APP_ENV='test',
    JWT_SECRET='test-only-signing-secret-with-more-than-32-chars',RABBITMQ_PASSWORD='test-only-password',
    PAYMENT_DELAY_MS='0',RESTAURANT_DELAY_MS='0',DELIVERY_DELAY_MS='0',NOTIFICATION_DELAY_MS='0')
from app.database.session import Session,engine
from app.models.entities import Base
from app.database.seed import seed
from app.main import app

@pytest_asyncio.fixture(autouse=True)
async def clean_database():
    async with engine.begin() as connection:
        tables=', '.join('"'+t.name+'"' for t in Base.metadata.sorted_tables)
        await connection.execute(text('TRUNCATE '+tables+' CASCADE'))
    await seed()
    yield
    await engine.dispose()

@pytest_asyncio.fixture
async def client():
    async with httpx.AsyncClient(transport=httpx.ASGITransport(app=app,raise_app_exceptions=False),base_url='http://test') as c:yield c

@pytest_asyncio.fixture
async def headers(client):
    r=await client.post('/api/v1/auth/login',json={'email':'customer@quickbite.test','password':'Customer@12345'})
    return {'Authorization':'Bearer '+r.json()['access_token']}

@pytest_asyncio.fixture
async def admin_headers(client):
    r=await client.post('/api/v1/auth/login',json={'email':'admin@quickbite.test','password':'Admin@12345'})
    return {'Authorization':'Bearer '+r.json()['access_token']}
