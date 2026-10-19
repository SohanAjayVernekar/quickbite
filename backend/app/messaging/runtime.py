import asyncio
import base64
import hashlib
import json
import signal
from pathlib import Path
from time import perf_counter
from pydantic import ValidationError
from app.messaging.topology import connect
from app.schemas.contracts import Event
from app.services.processor import process
from app.services.reliability import save_failure
from app.services.simulation import ProcessingFailure
from app.config.logging import log
from app.config.settings import settings
from app.database.session import engine

HEARTBEAT=Path('/tmp/quickbite-heartbeat')
def heartbeat(): HEARTBEAT.touch()
def stop_signal():
    stop=asyncio.Event()
    for sig in [signal.SIGINT,signal.SIGTERM]:
        asyncio.get_running_loop().add_signal_handler(sig,stop.set)
    return stop
async def pause(stop,seconds):
    try: await asyncio.wait_for(stop.wait(),seconds)
    except TimeoutError: pass

async def handle(consumer,message):
    start=perf_counter(); event=None; attempt=0
    identity=hashlib.sha256(message.body).hexdigest()
    original={'raw_base64':base64.b64encode(message.body).decode()}
    try:
        if len(message.body)>1_048_576: raise ValueError('oversize')
        decoded=json.loads(message.body)
        if isinstance(decoded,dict): original=decoded
        event=Event.model_validate(decoded)
        if message.message_id!=event.event_id: raise ValueError('message_id_mismatch')
        raw_attempt=(message.headers or {}).get('attempt',0)
        if isinstance(raw_attempt,bool) or not isinstance(raw_attempt,int) or not 0<=raw_attempt<=3: raise ValueError('bad_attempt')
        attempt=raw_attempt
        if attempt and (message.headers or {}).get('consumer')!=consumer: raise ValueError('wrong_retry_target')
        identity=event.event_id
    except (ValueError,TypeError,ValidationError,UnicodeDecodeError):
        event=None
        result=await save_failure(consumer,None,original,identity,0,'MALFORMED_ENVELOPE',True)
    else:
        try: result=await process(consumer,event,attempt)
        except ProcessingFailure as e:
            result=await save_failure(consumer,event,original,identity,attempt,e.code,e.permanent)
        except Exception as e:
            log(consumer,'processing_rolled_back',event_id=identity,order_id=event.order_id,error_type=type(e).__name__)
            result=await save_failure(consumer,event,original,identity,attempt,'PROCESSING_ERROR')
    # Every path above has either committed a business transaction, retry, or quarantine.
    await message.ack()
    log(consumer,result,event_id=identity,order_id=event.order_id if event else None,
        correlation_id=event.correlation_id if event else None,attempt=attempt,
        elapsed_ms=round((perf_counter()-start)*1000,2))

async def run_consumer(consumer):
    stop=stop_signal(); backoff=1
    while not stop.is_set():
        connection=None
        try:
            connection,channel=await connect()
            queue=await channel.get_queue(consumer+'.queue')
            pending=asyncio.Queue(maxsize=settings().prefetch)
            async def receive(message): await pending.put(message)
            tag=await queue.consume(receive,no_ack=False)
            backoff=1
            while not stop.is_set() and not connection.is_closed:
                heartbeat()
                try: message=await asyncio.wait_for(pending.get(),1)
                except TimeoutError: continue
                # A scheduling DB failure escapes without ACK. Closing the channel requeues safely.
                await handle(consumer,message)
            await queue.cancel(tag)
        except Exception as e:
            log(consumer,'reconnecting',error_type=type(e).__name__)
        finally:
            if connection and not connection.is_closed:
                await connection.close()
        if not stop.is_set():
            await pause(stop,backoff);backoff=min(30,backoff*2)
    await engine.dispose()
