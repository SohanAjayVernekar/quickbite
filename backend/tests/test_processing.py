import asyncio
from uuid import uuid4
from sqlalchemy import select,func
from app.database.session import Session
from app.models.entities import Outbox,Order,Payment,Assignment,History,Notification,RetryJob,Quarantine
from app.schemas.contracts import Checkout,Event
from app.services.checkout import accept_order
from app.services.processor import process
from app.services.reliability import save_failure
from app.services.simulation import ProcessingFailure
from app.config.settings import settings
from app.messaging.retry_scheduler import release_due

async def created():
    result=await accept_order('customer-demo',str(uuid4()),Checkout(restaurant_id='saffron',delivery_address='10 Test Garden Road, Bengaluru',items=[{'menu_item_id':'saffron-1','quantity':1}]),str(uuid4()))
    async with Session() as s:
        row=await s.scalar(select(Outbox).where(Outbox.routing_key=='order.created'))
        return result['order_id'],Event.model_validate(row.payload)
async def child(kind):
    async with Session() as s:return Event.model_validate((await s.scalar(select(Outbox).where(Outbox.routing_key==kind))).payload)

async def test_happy_path_duplicate_effects():
    id,event=await created()
    await asyncio.gather(*(process('payment',event,0) for _ in range(5)))
    paid=await child('order.paid');await process('restaurant',paid,0)
    confirmed=await child('order.confirmed');await process('delivery',confirmed,0)
    for e in [event,paid,confirmed,await child('order.driver.assigned')]:
        await process('notification',e,0);await process('notification',e,0)
    await process('payment',event,0)
    async with Session() as s:
        order=await s.get(Order,id);assert order.status=='DRIVER_ASSIGNED' and order.version==4
        for model,expected in [(Payment,1),(Assignment,1),(History,4),(Notification,4)]:assert await s.scalar(select(func.count()).select_from(model))==expected

async def test_future_event_bounded_defer():
    id,event=await created()
    future=event.model_copy(update={'event_id':str(uuid4()),'event_type':'order.paid','order_version':2})
    try:await process('restaurant',future,0)
    except ProcessingFailure as e:assert e.code=='FUTURE_VERSION'
    else:raise AssertionError('Future prerequisite must not be silently lost')
    async with Session() as s:assert (await s.get(Order,id)).status=='PENDING'

async def test_fail_twice_then_succeed(monkeypatch):
    cfg=settings();monkeypatch.setattr(cfg,'enable_demo_failures',True);monkeypatch.setattr(cfg,'demo_mode','payment_fail_twice');monkeypatch.setattr(cfg,'retry_delays','0.02,0.05,0.1')
    id,event=await created()
    for attempt in range(2):
        try:await process('payment',event,attempt)
        except ProcessingFailure as e:await save_failure('payment',event,event.model_dump(mode='json'),event.event_id,attempt,e.code)
        else:raise AssertionError('Expected deterministic failure')
        await asyncio.sleep(cfg.delays[attempt]+.02);await release_due()
    await process('payment',event,2)
    async with Session() as s:
        assert (await s.get(Order,id)).status=='PAID'
        assert await s.scalar(select(func.count()).select_from(Payment))==1
        jobs=(await s.scalars(select(RetryJob))).all();assert len(jobs)==2
        for job in jobs:
            publication=await s.get(Outbox,job.outbox_id)
            assert publication.exchange=='' and publication.routing_key=='payment.queue' and publication.event_id==event.event_id

async def test_exhaustion_and_notification_isolation():
    id,event=await created()
    for attempt in range(4):await save_failure('payment',event,event.model_dump(mode='json'),event.event_id,attempt,'PAYMENT_TRANSIENT')
    async with Session() as s:
        assert (await s.get(Order,id)).status=='PAYMENT_FAILED'
        assert await s.scalar(select(func.count()).select_from(Quarantine))==1
        assert await s.scalar(select(func.count()).select_from(Outbox).where(Outbox.exchange=='quickbite.dead'))==1
    await save_failure('notification',event,event.model_dump(mode='json'),event.event_id,3,'NOTIFICATION_TRANSIENT')
    async with Session() as s:assert (await s.get(Order,id)).status=='PAYMENT_FAILED'
