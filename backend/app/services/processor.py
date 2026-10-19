from sqlalchemy import select,update
from app.models.entities import Order,ProcessedEvent,RetryJob,Quarantine,Payment,Assignment,Driver,Notification
from app.database.session import Session,event_lock
from app.domain.state import EXPECTED,RANK,TERMINAL
from app.messaging.events import transition
from app.services.simulation import ProcessingFailure,simulate,checkpoint
from app.config.logging import log

MESSAGES={
 'order.created':('Order accepted','Your order is queued for processing.'),
 'order.paid':('Payment successful','Your simulated payment is complete.'),
 'order.payment.failed':('Payment failed','Payment processing did not complete. Open your order for details.'),
 'order.confirmed':('Restaurant confirmed','The restaurant accepted your order.'),
 'order.driver.assigned':('Driver assigned','Your simulated driver is assigned. This is the final stage of the demo.'),
 'order.failed':('Order could not continue','Open your order to see the processing failure.'),
}
async def already_handled(s,consumer,event_id,attempt):
    if await s.get(ProcessedEvent,(consumer,event_id)): return True
    if await s.scalar(select(Quarantine.id).where(Quarantine.consumer_name==consumer,Quarantine.event_id==event_id)): return True
    # Duplicate older delivery must not overtake a durable scheduled retry.
    if await s.scalar(select(RetryJob.id).where(RetryJob.consumer_name==consumer,RetryJob.event_id==event_id,RetryJob.attempt>attempt)): return True
    return False

async def process(consumer,event,attempt):
    async with Session() as s,s.begin():
        await event_lock(s,consumer,event.event_id)
        if await already_handled(s,consumer,event.event_id,attempt): return 'duplicate'
        if attempt:
            job=await s.scalar(select(RetryJob).where(RetryJob.consumer_name==consumer,RetryJob.event_id==event.event_id,RetryJob.attempt==attempt))
            if not job: raise ProcessingFailure('UNRECOGNIZED_RETRY',True)
        order=await s.scalar(select(Order).where(Order.id==event.order_id).with_for_update())
        if not order: raise ProcessingFailure('ORDER_MISSING')
        if event.order_version>order.version: raise ProcessingFailure('FUTURE_VERSION')
        outcome='processed'
        if consumer=='notification':
            if event.event_type not in MESSAGES:
                outcome='ignored_future_type'
                log(consumer,outcome,event_id=event.event_id,order_id=order.id)
            else:
                await simulate(consumer,attempt)
                title,message=MESSAGES[event.event_type]
                s.add(Notification(customer_id=order.customer_id,order_id=order.id,event_id=event.event_id,
                    order_version=event.order_version,title=title,message=message))
        else:
            expected_event,expected_status=EXPECTED[consumer]
            if event.event_type!=expected_event: raise ProcessingFailure('UNSUPPORTED_EVENT',True)
            if order.status!=expected_status:
                if order.status in TERMINAL or RANK.get(order.status,0)>RANK[expected_status]: outcome='stale'
                else: raise ProcessingFailure('PREREQUISITE_PENDING')
            elif event.order_version!=order.version:
                raise ProcessingFailure('STATE_VERSION_MISMATCH',True)
            else:
                await simulate(consumer,attempt)
                if consumer=='payment':
                    payment=Payment(order_id=order.id,amount_minor=order.total_amount_minor,status='SUCCEEDED',idempotency_key='payment:'+order.id)
                    s.add(payment); await s.flush()
                    transition(s,order,'PAID','order.paid',event,{'payment_id':payment.id})
                elif consumer=='restaurant': transition(s,order,'CONFIRMED','order.confirmed',event)
                elif consumer=='delivery':
                    drivers=(await s.scalars(select(Driver).where(Driver.active.is_(True)).order_by(Driver.id))).all()
                    if not drivers: raise ProcessingFailure('NO_DRIVERS')
                    import hashlib
                    driver=drivers[int(hashlib.sha256(order.id.encode()).hexdigest(),16)%len(drivers)]
                    assignment=Assignment(order_id=order.id,driver_id=driver.id); s.add(assignment)
                    order.driver_id=driver.id
                    transition(s,order,'DRIVER_ASSIGNED','order.driver.assigned',event,{'driver_id':driver.id})
        s.add(ProcessedEvent(consumer_name=consumer,event_id=event.event_id,result=outcome))
        await s.execute(update(RetryJob).where(RetryJob.consumer_name==consumer,RetryJob.event_id==event.event_id).values(state='DONE'))
        await s.flush()
        await checkpoint(consumer,event.event_id,'before_commit')
    await checkpoint(consumer,event.event_id,'after_commit_before_ack')
    return outcome
