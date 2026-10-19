import asyncio
import os
from sqlalchemy.dialects.postgresql import insert
from app.config.settings import settings
from app.database.session import Session
from app.models.entities import DemoCheckpoint
from app.config.logging import log

class ProcessingFailure(Exception):
    def __init__(self,code,permanent=False): self.code,self.permanent=code,permanent

async def simulate(consumer,attempt):
    cfg=settings()
    await asyncio.sleep(getattr(cfg,consumer+'_delay_ms')/1000)
    if not cfg.enable_demo_failures: return
    mode=cfg.demo_mode
    if consumer=='payment':
        if mode=='payment_decline': raise ProcessingFailure('PAYMENT_DECLINED',True)
        if mode=='payment_always_fail' or (mode=='payment_fail_twice' and attempt<2):
            raise ProcessingFailure('PAYMENT_TRANSIENT')
    if consumer=='restaurant' and mode=='restaurant_terminal': raise ProcessingFailure('RESTAURANT_UNAVAILABLE',True)
    if consumer=='delivery' and mode=='delivery_terminal': raise ProcessingFailure('DELIVERY_UNAVAILABLE',True)
    if consumer=='notification' and mode=='notification_fail': raise ProcessingFailure('NOTIFICATION_TRANSIENT')

async def checkpoint(service,identity,point):
    cfg=settings()
    if not(cfg.enable_demo_failures and cfg.crash_service==service and cfg.crash_checkpoint==point): return
    # Separate durable transaction ensures each selected boundary crashes once per identity.
    async with Session() as s,s.begin():
        first=await s.scalar(insert(DemoCheckpoint).values(service=service,identity=identity,checkpoint=point)
            .on_conflict_do_nothing().returning(DemoCheckpoint.identity))
    if first:
        log(service,'intentional_demo_crash',event_id=identity,checkpoint=point)
        os._exit(86)
