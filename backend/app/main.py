import asyncio
from contextlib import asynccontextmanager
from time import perf_counter
from uuid import uuid4, UUID
import aio_pika
from fastapi import FastAPI,Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from sqlalchemy import text
from app.config.settings import settings
from app.config.logging import log
from app.database.session import engine,Session
from app.api.routes import router
from app.api.errors import register_errors
from app.schemas.responses import ErrorView

@asynccontextmanager
async def lifespan(app):
    yield
    await engine.dispose()

app=FastAPI(title='QuickBite API',version='1.0.0',description='Server-priced checkout and asynchronous food order processing.',lifespan=lifespan,responses={code:{'model':ErrorView} for code in [401,403,404,409,422,503]})
register_errors(app)
app.add_middleware(CORSMiddleware,allow_origins=settings().origins,allow_credentials=False,
    allow_methods=['GET','POST','PATCH','DELETE','OPTIONS'],allow_headers=['Authorization','Content-Type','Idempotency-Key','X-Request-ID'],
    expose_headers=['Location','X-Request-ID'])

@app.middleware('http')
async def correlation(request:Request,call_next):
    try: request_id=str(UUID(request.headers.get('X-Request-ID','')))
    except ValueError: request_id=str(uuid4())
    request.state.request_id=request_id; started=perf_counter()
    response=await call_next(request)
    response.headers['X-Request-ID']=request_id
    response.headers['X-Content-Type-Options']='nosniff'
    if request.url.path.startswith('/api/v1') and not request.url.path.startswith('/api/v1/public/'):
        response.headers['Cache-Control']='no-store'
    log('api',str(response.status_code),request_id=request_id,elapsed_ms=round((perf_counter()-started)*1000,2))
    return response

app.include_router(router)

@app.get('/health/live',tags=['Health'])
async def live(): return {'status':'alive'}

@app.get('/health/ready',tags=['Health'])
async def ready():
    async def database():
        async with Session() as s: await s.execute(text('SELECT 1 FROM alembic_version LIMIT 1'))
    db=True; broker=True
    try: await asyncio.wait_for(database(),2)
    except Exception: db=False
    try:
        connection=await aio_pika.connect(settings().amqp_url,timeout=1)
        await connection.close()
    except Exception: broker=False
    return JSONResponse({'status':'ready' if db else 'not_ready','database':db,'broker':broker,
                         'messaging':'available' if broker else 'deferred_to_outbox',
                         'semantics':'PostgreSQL is required for acceptance; broker recovery is asynchronous.'},status_code=200 if db else 503)
