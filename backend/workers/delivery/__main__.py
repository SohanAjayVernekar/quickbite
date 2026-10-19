import asyncio
from app.messaging.runtime import run_consumer
asyncio.run(run_consumer('delivery'))
