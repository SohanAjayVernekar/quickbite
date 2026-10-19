import json
import logging
import socket
from datetime import datetime, timezone

logging.basicConfig(level=logging.INFO, format='%(message)s')
logging.getLogger('sqlalchemy.engine').setLevel(logging.WARNING)
logging.getLogger('aio_pika').setLevel(logging.WARNING)
logging.getLogger('aiormq').setLevel(logging.WARNING)
logging.getLogger('httpx').setLevel(logging.WARNING)

def log(service: str, result: str, **fields):
    allowed = {'request_id','correlation_id','order_id','event_id','attempt','transition',
               'elapsed_ms','error_type','checkpoint','publication_id','consumer','queue'}
    safe = {k:v for k,v in fields.items() if k in allowed}
    logging.getLogger('quickbite').info(json.dumps({
        'timestamp': datetime.now(timezone.utc).isoformat(), 'service': service, 'instance': socket.gethostname(),
        'result': result, **safe}, default=str))
