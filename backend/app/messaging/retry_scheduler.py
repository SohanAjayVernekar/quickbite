import asyncio
from sqlalchemy import select
from app.database.session import Session,engine
from app.models.entities import RetryJob,Outbox,utcnow
from app.messaging.runtime import stop_signal,pause,heartbeat
from app.config.logging import log

async def release_due():
    async with Session() as s,s.begin():
        jobs=(await s.scalars(select(RetryJob).where(RetryJob.state=='SCHEDULED',RetryJob.due_at<=utcnow())
            .order_by(RetryJob.due_at).with_for_update(skip_locked=True).limit(100))).all()
        for job in jobs:
            publication=await s.get(Outbox,job.outbox_id,with_for_update=True)
            if publication.state=='BLOCKED': publication.state='PENDING'
            job.state='RELEASED'
            log('retry_scheduler','released',event_id=job.event_id,attempt=job.attempt,consumer=job.consumer_name)

async def run():
    stop=stop_signal();backoff=1
    while not stop.is_set():
        try:
            await release_due();heartbeat();backoff=1;await pause(stop,.2)
        except Exception as e:
            log('retry_scheduler','database_backoff',error_type=type(e).__name__)
            await pause(stop,backoff);backoff=min(30,backoff*2)
    await engine.dispose()
if __name__=='__main__': asyncio.run(run())
