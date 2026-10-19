import hashlib
import json
from sqlalchemy import select, text
from app.models.entities import Restaurant, MenuItem, Order, OrderItem, History, Idempotency, uid
from app.database.session import Session
from app.schemas.contracts import Checkout
from app.messaging.events import make_event,enqueue
from app.api.errors import ApiError

def canonical_hash(request):
    payload=request.model_dump()
    payload['items']=sorted(payload['items'],key=lambda x:x['menu_item_id'])
    return hashlib.sha256(json.dumps(payload,sort_keys=True,separators=(',',':'),ensure_ascii=False).encode()).hexdigest()

async def accept_order(customer_id,key,request:Checkout,correlation_id):
    digest=canonical_hash(request)
    async with Session() as s, s.begin():
        # Transaction-scoped serialization handles concurrent first submissions, before insert.
        await s.execute(text('SELECT pg_advisory_xact_lock(hashtextextended(:key, 0))'),
                        {'key':f'checkout:{customer_id}:{key}'})
        prior=await s.get(Idempotency,(customer_id,key))
        if prior:
            if prior.request_hash!=digest:
                raise ApiError(409,'IDEMPOTENCY_CONFLICT','This checkout key was already used with different details.')
            return prior.response
        restaurant=await s.scalar(select(Restaurant).where(Restaurant.id==request.restaurant_id).with_for_update(read=True))
        if not restaurant or not restaurant.available:
            raise ApiError(422,'RESTAURANT_UNAVAILABLE','Choose an available restaurant.')
        ids=[x.menu_item_id for x in request.items]
        rows=(await s.scalars(select(MenuItem).where(MenuItem.id.in_(ids)).with_for_update(read=True))).all()
        items={x.id:x for x in rows}
        if len(items)!=len(ids): raise ApiError(422,'INVALID_MENU_ITEM','One or more menu items no longer exist.')
        for item in rows:
            if item.restaurant_id!=restaurant.id: raise ApiError(422,'MIXED_RESTAURANTS','An order must contain items from one restaurant.')
            if not item.available: raise ApiError(422,'MENU_ITEM_UNAVAILABLE',f'{item.name} is unavailable.')
            if item.currency!='INR': raise ApiError(422,'CURRENCY_MISMATCH','Menu currency is unsupported.')
        total=sum(items[x.menu_item_id].price_minor*x.quantity for x in request.items)
        order=Order(id='QB-'+uid(),customer_id=customer_id,restaurant_id=restaurant.id,
            delivery_address=request.delivery_address,currency='INR',total_amount_minor=total,status='PENDING',version=1)
        s.add(order); await s.flush()
        for x in request.items:
            item=items[x.menu_item_id]
            s.add(OrderItem(order_id=order.id,menu_item_id=item.id,item_name=item.name,
                            quantity=x.quantity,unit_price_minor=item.price_minor))
        event=make_event(order,'order.created',correlation_id,data={'restaurant_id':restaurant.id})
        s.add(History(order_id=order.id,status='PENDING',version=1,event_id=event.event_id))
        response={'order_id':order.id,'status':'PENDING','currency':'INR','total_amount_minor':total,
                  'version':1,'message':'Order accepted for asynchronous processing.'}
        s.add(Idempotency(customer_id=customer_id,key=key,request_hash=digest,order_id=order.id,response=response))
        enqueue(s,event)
        # Context exits (commits) before the API can return 202.
    return response
