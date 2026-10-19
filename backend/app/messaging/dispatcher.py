import asyncio
import json
from datetime import timedelta
import aio_pika
from pamqp.commands import Basic
from sqlalchemy import select,update
from app.database.session import Session,engine
from app.models.entities import Outbox,RetryJob,utcnow
from app.messaging.topology import connect
from app.messaging.runtime import stop_signal,pause,heartbeat
from app.services.simulation import checkpoint
from app.config.logging import log

async def dispatch_one(channel):
    async with Session() as s,s.begin():
        row=await s.scalar(select(Outbox).where(Outbox.state=='PENDING',Outbox.available_at<=utcnow())
            .order_by(Outbox.available_at,Outbox.id).with_for_update(skip_locked=True).limit(1))
        if not row: return False
        row.publish_attempts+=1
        try:
            exchange=channel.default_exchange if not row.exchange else await channel.get_exchange(row.exchange)
            message=aio_pika.Message(body=json.dumps(row.payload,separators=(',',':')).encode(),
                message_id=row.event_id,content_type='application/json',
                delivery_mode=aio_pika.DeliveryMode.PERSISTENT,headers=row.headers,
                correlation_id=row.payload.get('correlation_id'),timestamp=utcnow())
            confirmation=await exchange.publish(message,routing_key=row.routing_key,mandatory=True,timeout=5)
            if not isinstance(confirmation,Basic.Ack): raise RuntimeError('publisher_nack')
            await checkpoint('outbox',row.id,'publish_before_mark')
            row.state='SENT';row.sent_at=utcnow();row.last_error=None
            await s.execute(update(RetryJob).where(RetryJob.outbox_id==row.id,RetryJob.state=='RELEASED').values(state='PUBLISHED'))
            log('outbox','sent',event_id=row.event_id,publication_id=row.id)
        except Exception as e:
            row.last_error=type(e).__name__
            row.available_at=utcnow()+timedelta(seconds=min(30,2**min(row.publish_attempts,5)))
            log('outbox','deferred',event_id=row.event_id,error_type=type(e).__name__)
    return True

async def run():
    stop=stop_signal();backoff=1
    while not stop.is_set():
        connection=None
        try:
            connection,channel=await connect();backoff=1
            while not stop.is_set() and not connection.is_closed:
                heartbeat()
                if not await dispatch_one(channel): await pause(stop,.2)
        except Exception as e: log('outbox','reconnecting',error_type=type(e).__name__)
        finally:
            if connection and not connection.is_closed: await connection.close()
        if not stop.is_set(): await pause(stop,backoff);backoff=min(30,backoff*2)
    await engine.dispose()
if __name__=='__main__': asyncio.run(run())
