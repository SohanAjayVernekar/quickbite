from sqlalchemy.ext.asyncio import create_async_engine, async_sessionmaker
from sqlalchemy import text
from app.config.settings import settings

engine = create_async_engine(settings().database_url, pool_pre_ping=True, hide_parameters=True, pool_size=10,
    max_overflow=10, pool_timeout=5, connect_args={'timeout':5, 'command_timeout':20,
    'server_settings': {'timezone':'UTC', 'statement_timeout':'15000', 'lock_timeout':'10000'}})
Session = async_sessionmaker(engine, expire_on_commit=False)

async def event_lock(session, consumer, event_id):
    await session.execute(text('SELECT pg_advisory_xact_lock(hashtextextended(:key, 0))'),
                          {'key':f'{consumer}:{event_id}'})
