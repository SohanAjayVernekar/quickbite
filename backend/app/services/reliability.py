from datetime import timedelta
from sqlalchemy import select,update
from app.database.session import Session,event_lock
from app.models.entities import Outbox,RetryJob,Quarantine,Order,Payment,ProcessedEvent,utcnow,uid
from app.config.settings import settings
from app.domain.state import EXPECTED
from app.messaging.events import transition
from app.services.processor import already_handled

async def save_failure(consumer,event,original,identity,attempt,code,permanent=False):
    async with Session() as s,s.begin():
        await event_lock(s,consumer,identity)
        if await already_handled(s,consumer,identity,attempt): return 'already_scheduled'
        if not permanent and event is not None and attempt<len(settings().delays):
            next_attempt=attempt+1
            due=utcnow()+timedelta(seconds=settings().delays[attempt])
            publication_id=f'retry:{consumer}:{identity}:{next_attempt}'
            s.add(Outbox(id=publication_id,event_id=identity,payload=event.model_dump(mode='json'),
                exchange='',routing_key=consumer+'.queue',headers={'attempt':next_attempt,'consumer':consumer},
                available_at=due,state='BLOCKED'))
            await s.flush()
            s.add(RetryJob(consumer_name=consumer,event_id=identity,attempt=next_attempt,
                outbox_id=publication_id,due_at=due,failure_code=code))
            return 'retry_scheduled'
        quarantine=Quarantine(id=uid(),consumer_name=consumer,event_id=identity,source_queue=consumer+'.queue',
            original=original,attempts=attempt+1,failure_code=code,reason=code.replace('_',' ').lower())
        s.add(quarantine)
        payload={'quarantine_id':quarantine.id,'original_event':original,'source_consumer':consumer,
                 'source_queue':consumer+'.queue','attempts':attempt+1,'failure_code':code,'occurred_at':utcnow().isoformat()}
        s.add(Outbox(id=f'quarantine:{consumer}:{identity}',event_id=identity,payload=payload,
            exchange='quickbite.dead',routing_key='failed'))
        # Only fully validated events at the exact expected state/version may terminalize an order.
        if event is not None and consumer in EXPECTED:
            order=await s.scalar(select(Order).where(Order.id==event.order_id).with_for_update())
            kind,state=EXPECTED[consumer]
            if order and event.event_type==kind and order.status==state and event.order_version==order.version:
                failure=code if code in {'PAYMENT_DECLINED','RESTAURANT_UNAVAILABLE','DELIVERY_UNAVAILABLE'} else consumer.upper()+'_RETRIES_EXHAUSTED'
                if consumer=='payment':
                    s.add(Payment(order_id=order.id,amount_minor=order.total_amount_minor,status='FAILED',idempotency_key='payment:'+order.id))
                    transition(s,order,'PAYMENT_FAILED','order.payment.failed',event,{'failure_code':failure},failure)
                else: transition(s,order,'FAILED','order.failed',event,{'failure_code':failure},failure)
        await s.execute(update(RetryJob).where(RetryJob.consumer_name==consumer,RetryJob.event_id==identity).values(state='QUARANTINED'))
        s.add(ProcessedEvent(consumer_name=consumer,event_id=identity,result='quarantined'))
        return 'quarantined'
