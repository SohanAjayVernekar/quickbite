import json
from uuid import uuid4
import aio_pika
from app.messaging.topology import connect
from app.models.entities import utcnow
from app.schemas.contracts import Event

async def test_real_notification_queue_multisegment_binding():
    connection,channel=await connect()
    try:
        queue=await channel.get_queue('notification.queue');await queue.purge()
        exchange=await channel.get_exchange('quickbite.orders')
        for kind in ['order.paid','order.payment.failed','order.driver.assigned']:
            event=Event(event_id=str(uuid4()),schema_version=1,event_type=kind,order_id='test-order',order_version=1,occurred_at=utcnow(),correlation_id=str(uuid4()),causation_id=None,data={})
            await exchange.publish(aio_pika.Message(event.model_dump_json().encode(),message_id=event.event_id,delivery_mode=aio_pika.DeliveryMode.PERSISTENT),routing_key=kind,mandatory=True)
            message=await queue.get(timeout=5)
            assert json.loads(message.body)['event_type']==kind
            await message.ack()
    finally:await connection.close()
