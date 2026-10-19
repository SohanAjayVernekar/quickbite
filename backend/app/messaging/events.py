from app.models.entities import Outbox, History, utcnow, uid
from app.schemas.contracts import Event
from app.domain.state import TRANSITIONS

def make_event(order,event_type,correlation_id,causation_id=None,data=None):
    return Event(event_id=uid(),schema_version=1,event_type=event_type,order_id=order.id,
        order_version=order.version,occurred_at=utcnow(),correlation_id=correlation_id,
        causation_id=causation_id,data=data or {})

def enqueue(session,event):
    session.add(Outbox(id=f'domain:{event.event_id}',event_id=event.event_id,
        payload=event.model_dump(mode='json'),exchange='quickbite.orders',routing_key=event.event_type))

def transition(session,order,target,event_type,incoming,data=None,failure_code=None):
    if target not in TRANSITIONS.get(order.status,set()):
        raise ValueError('Forbidden state transition')
    order.status=target; order.version+=1; order.updated_at=utcnow(); order.failure_code=failure_code
    event=make_event(order,event_type,incoming.correlation_id,incoming.event_id,data)
    session.add(History(order_id=order.id,status=target,version=order.version,
        event_id=event.event_id,failure_code=failure_code))
    enqueue(session,event)
    return event
