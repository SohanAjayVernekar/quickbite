import aio_pika

BINDINGS={'payment.queue':'order.created','restaurant.queue':'order.paid',
          'delivery.queue':'order.confirmed','notification.queue':'order.#'}
async def connect():
    from app.config.settings import settings
    connection=await aio_pika.connect(settings().amqp_url,timeout=5)
    try:
        channel=await connection.channel(publisher_confirms=True,on_return_raises=True)
        await channel.set_qos(prefetch_count=settings().prefetch)
        exchange=await channel.declare_exchange('quickbite.orders',aio_pika.ExchangeType.TOPIC,durable=True)
        for name,key in BINDINGS.items():
            queue=await channel.declare_queue(name,durable=True,exclusive=False,auto_delete=False)
            await queue.bind(exchange,routing_key=key)
        dead=await channel.declare_exchange('quickbite.dead',aio_pika.ExchangeType.DIRECT,durable=True)
        queue=await channel.declare_queue('orders.dead-letter.queue',durable=True,exclusive=False,auto_delete=False)
        await queue.bind(dead,routing_key='failed')
        return connection,channel
    except BaseException:
        await connection.close(); raise
