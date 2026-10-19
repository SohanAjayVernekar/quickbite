import asyncio
import json
from datetime import timedelta
from pathlib import Path
from typing import Annotated, Literal
from uuid import UUID
import httpx
from fastapi import APIRouter, Depends, Header, Query, Request, Response
from sqlalchemy import select, func, delete, or_
from app.database.session import Session
from app.models.entities import User, Restaurant, MenuItem, Order, History, Notification, Outbox, RetryJob, Quarantine, Payment, Driver, Assignment, ProcessedEvent, Refund
from app.schemas.contracts import Login, Checkout, RestaurantCreate, DishCreate, AvailabilityUpdate
from app.schemas.responses import (TokenView,UserView,CatalogView,Page,RestaurantView,MenuPage,MenuItemView,AcceptanceView,OrderView,DetailView,HistoryView,NotificationView,SummaryView,PaymentRecordView,DriverView,StuckOrderView,AnalyticsView)
from app.auth.security import current_user,customer,admin,profile,verify,issue_token,DUMMY_HASH
from app.services.checkout import accept_order
from app.services.queries import paginate,accessible_order,order_detail,order_page,row_dict
from app.api.errors import ApiError
from app.domain.state import Status
from app.config.settings import settings

router=APIRouter(prefix='/api/v1')
PageNumber=Annotated[int,Query(ge=1)]
Size=Annotated[int,Query(ge=1,le=100)]
# Menus now hold 100 dishes per kitchen, so a larger batch keeps infinite
# scroll from issuing a request per handful of cards.
MenuSize=Annotated[int,Query(ge=1,le=100)]

@router.post('/auth/login',response_model=TokenView,tags=['Authentication'])
async def login(data:Login,response:Response):
    async with Session() as s: user=await s.scalar(select(User).where(User.email==data.email.strip().lower()))
    valid=await asyncio.to_thread(verify,data.password,user.password_hash if user else DUMMY_HASH)
    if not user or not valid or not user.active:
        raise ApiError(401,'INVALID_CREDENTIALS','Email or password is incorrect.')
    response.headers['Cache-Control']='no-store'
    return issue_token(user)

@router.get('/me',response_model=UserView,tags=['Authentication'])
async def me(user:User=Depends(current_user)): return profile(user)

@router.get('/public/catalog',response_model=CatalogView,tags=['Public preview'])
async def public_catalog():
    # Deliberately separate from the assignment's authenticated browsing endpoints.
    async with Session() as s:
        featured=['saffron','ember','bun','wok','kitchen-005','kitchen-006','kitchen-007','kitchen-013']
        restaurants=(await s.scalars(select(Restaurant).where(Restaurant.available.is_(True),Restaurant.id.in_(featured)).order_by(Restaurant.name))).all()
        # Showcase only dishes that ship with real imagery (your photo/ gallery
        # or the bundled photography); illustration-only dishes would render
        # as plain cartoons on the landing strip. One dish per featured kitchen.
        real=(await s.scalars(select(MenuItem).where(
            MenuItem.available.is_(True),
            MenuItem.restaurant_id.in_(featured),
            ~MenuItem.image.startswith('generated/')).order_by(MenuItem.id))).all()
        picked, seen = {}, []
        for d in real:
            if d.restaurant_id not in seen:
                seen.append(d.restaurant_id); picked[d.restaurant_id] = d
        if len(picked) < len(featured):
            for d in (await s.scalars(select(MenuItem).where(MenuItem.available.is_(True),MenuItem.id.in_([rid+'-1' for rid in featured])).order_by(MenuItem.id))):
                if d.restaurant_id not in seen:
                    seen.append(d.restaurant_id); picked[d.restaurant_id] = d
        dishes=sorted(picked.values(), key=lambda x: (x.image.startswith('generated/'), x.id))
        total=await s.scalar(select(func.count()).select_from(Restaurant))
        cuisines=(await s.scalars(select(Restaurant.cuisine).distinct().order_by(Restaurant.cuisine))).all()
        return {'restaurants':[row_dict(x) for x in restaurants],'dishes':[row_dict(x) for x in dishes],
                'total_restaurants':total,'cuisines':list(cuisines)}

@router.get('/restaurants',response_model=Page[RestaurantView],tags=['Catalogue'])
async def restaurants(page:PageNumber=1,page_size:Size=20,q:str=Query('',max_length=100),
                      cuisine:str=Query('',max_length=80),vegetarian:bool=False,
                      min_rating:int=Query(0,ge=0,le=50),
                      sort:Literal['recommended','rating','fastest','name']='recommended',
                      user:User=Depends(current_user)):
    stmt=select(Restaurant)
    if q.strip():
        term=q.strip()
        dish_match=select(MenuItem.id).where(MenuItem.restaurant_id==Restaurant.id,
                                             MenuItem.name.icontains(term,autoescape=True)).exists()
        stmt=stmt.where(Restaurant.name.icontains(term,autoescape=True)|
                        Restaurant.cuisine.icontains(term,autoescape=True)|dish_match)
    if cuisine: stmt=stmt.where(Restaurant.cuisine==cuisine)
    if vegetarian:
        stmt=stmt.where(select(MenuItem.id).where(MenuItem.restaurant_id==Restaurant.id,
                        MenuItem.vegetarian.is_(True),MenuItem.available.is_(True)).exists())
    if min_rating: stmt=stmt.where(Restaurant.rating_tenths>=min_rating)
    if sort=='fastest': stmt=stmt.order_by(Restaurant.eta_minutes,Restaurant.id)
    elif sort in ('recommended','rating'): stmt=stmt.order_by(Restaurant.rating_tenths.desc(),Restaurant.name,Restaurant.id)
    else: stmt=stmt.order_by(Restaurant.name,Restaurant.id)
    async with Session() as s: return await paginate(s,stmt,page,page_size)

@router.get('/restaurants/{restaurant_id}/menu',response_model=MenuPage,tags=['Catalogue'])
async def menu(restaurant_id:str,page:PageNumber=1,page_size:MenuSize=40,diet:Literal['all','veg','non_veg']='all',
               available:bool=False,with_photo:bool=False,
               sort:Literal['recommended','name','price_asc','price_desc','veg_first','photo_first']='recommended',
               q:str=Query('',max_length=100),user:User=Depends(current_user)):
    """Customer menu with filtering, search, sorting and offset pagination.

    Offset paging is kept deliberately: it matches the existing Pagination
    control and lets a caller jump to a known page. page_size is capped at 100
    so a single request cannot pull an entire kitchen.
    """
    async with Session() as s:
        r=await s.get(Restaurant,restaurant_id)
        if not r: raise ApiError(404,'RESTAURANT_NOT_FOUND','Restaurant not found.')
        stmt=select(MenuItem).where(MenuItem.restaurant_id==r.id)
        if diet=='veg': stmt=stmt.where(MenuItem.vegetarian.is_(True))
        elif diet=='non_veg': stmt=stmt.where(MenuItem.vegetarian.is_(False))
        if available: stmt=stmt.where(MenuItem.available.is_(True))
        if with_photo: stmt=stmt.where(MenuItem.image.startswith('photo/'))
        term=q.strip()
        if term:
            like=f'%{term}%'
            stmt=stmt.where(or_(MenuItem.name.ilike(like),MenuItem.description.ilike(like)))
        # id is the tiebreaker on every sort so paging stays stable when
        # several dishes share a name or price.
        #
        # 'recommended' groups the menu the way a kitchen presents it: plain
        # portions of each recipe first, then the chef's picks and sharing
        # plates. Sorting by name instead scatters one recipe's regular and
        # sharing versions apart, which reads as an unrelated list.
        plain = MenuItem.name.op('NOT LIKE')(' · %')
        has_photo = MenuItem.image.startswith('photo/')
        order={'recommended':(plain.desc(),MenuItem.name,MenuItem.id),
               'name':(MenuItem.name,MenuItem.id),
               'price_asc':(MenuItem.price_minor,MenuItem.id),
               'price_desc':(MenuItem.price_minor.desc(),MenuItem.id),
               'veg_first':(MenuItem.vegetarian.desc(),MenuItem.name,MenuItem.id),
               'photo_first':(has_photo.desc(),MenuItem.name,MenuItem.id)}[sort]
        result=await paginate(s,stmt.order_by(*order),page,page_size)
        result['restaurant']=row_dict(r)
        result['filters']={'diet':diet,'available':available,'with_photo':with_photo,'sort':sort,'q':term}
        return result

@router.post('/admin/restaurants',response_model=RestaurantView,status_code=201,tags=['Administration'])
async def create_restaurant(data:RestaurantCreate,user:User=Depends(admin)):
    from uuid import uuid4
    restaurant=Restaurant(id=f'admin-{uuid4().hex[:20]}',name=data.name,cuisine=data.cuisine,
        description=data.description,image=data.image,available=data.available,
        rating_tenths=45,eta_minutes=data.eta_minutes)
    async with Session() as s,s.begin():
        s.add(restaurant)
    return row_dict(restaurant)

@router.patch('/admin/restaurants/{restaurant_id}/availability',response_model=RestaurantView,tags=['Administration'])
async def set_restaurant_availability(restaurant_id:str,data:AvailabilityUpdate,user:User=Depends(admin)):
    async with Session() as s,s.begin():
        restaurant=await s.get(Restaurant,restaurant_id,with_for_update=True)
        if restaurant is None: raise ApiError(404,'RESTAURANT_NOT_FOUND','Restaurant not found.')
        restaurant.available=data.available
        await s.flush()
        result=row_dict(restaurant)
    return result

@router.delete('/admin/restaurants/{restaurant_id}',tags=['Administration'])
async def delete_restaurant(restaurant_id:str,user:User=Depends(admin)):
    async with Session() as s,s.begin():
        restaurant=await s.get(Restaurant,restaurant_id,with_for_update=True)
        if restaurant is None: raise ApiError(404,'RESTAURANT_NOT_FOUND','Restaurant not found.')
        order_count=await s.scalar(select(func.count()).select_from(Order).where(Order.restaurant_id==restaurant_id))
        if order_count:
            raise ApiError(409,'RESTAURANT_HAS_ORDERS',
                'This restaurant has order history and cannot be deleted. Mark it unavailable instead.')
        dishes=(await s.scalars(select(MenuItem).where(MenuItem.restaurant_id==restaurant_id).with_for_update())).all()
        dish_ids=[dish.id for dish in dishes]
        if dish_ids:
            line_count=await s.scalar(select(func.count()).select_from(OrderItem).where(OrderItem.menu_item_id.in_(dish_ids)))
            if line_count:
                raise ApiError(409,'RESTAURANT_HAS_ORDER_ITEMS',
                    'This restaurant has order history and cannot be deleted. Mark it unavailable instead.')
            for dish in dishes: await s.delete(dish)
        await s.delete(restaurant)
    return {'id':restaurant_id,'deleted':True}

@router.post('/admin/restaurants/{restaurant_id}/dishes',response_model=MenuItemView,status_code=201,tags=['Administration'])
async def create_dish(restaurant_id:str,data:DishCreate,user:User=Depends(admin)):
    from uuid import uuid4
    from app.database.catalog import dish_image
    generated_map=json.loads((Path(__file__).resolve().parents[1]/'database'/'generated_dish_images.json').read_text())
    async with Session() as s,s.begin():
        restaurant=await s.get(Restaurant,restaurant_id)
        if restaurant is None: raise ApiError(404,'RESTAURANT_NOT_FOUND','Restaurant not found.')
        dish_id=f'admin-{uuid4().hex[:24]}'
        image=(data.image or dish_image(data.name,'') or generated_map.get(data.name)
               or f'generated:auto/{dish_id}')
        dish=MenuItem(id=dish_id,restaurant_id=restaurant_id,
            name=data.name,description=data.description,image=image,price_minor=data.price_minor,
            currency=data.currency.upper(),available=data.available,vegetarian=data.vegetarian)
        s.add(dish)
        await s.flush()
        result=row_dict(dish)
    return result

@router.patch('/admin/dishes/{dish_id}/availability',response_model=MenuItemView,tags=['Administration'])
async def set_dish_availability(dish_id:str,data:AvailabilityUpdate,user:User=Depends(admin)):
    async with Session() as s,s.begin():
        dish=await s.get(MenuItem,dish_id,with_for_update=True)
        if dish is None: raise ApiError(404,'DISH_NOT_FOUND','Dish not found.')
        dish.available=data.available
        await s.flush()
        result=row_dict(dish)
    return result

@router.delete('/admin/dishes/{dish_id}',tags=['Administration'])
async def delete_dish(dish_id:str,user:User=Depends(admin)):
    async with Session() as s,s.begin():
        dish=await s.get(MenuItem,dish_id,with_for_update=True)
        if dish is None: raise ApiError(404,'DISH_NOT_FOUND','Dish not found.')
        line_count=await s.scalar(select(func.count()).select_from(OrderItem).where(OrderItem.menu_item_id==dish_id))
        if line_count:
            raise ApiError(409,'DISH_HAS_ORDERS',
                'This dish appears in order history and cannot be deleted. Mark it unavailable instead.')
        await s.delete(dish)
    return {'id':dish_id,'deleted':True}

@router.post('/orders',response_model=AcceptanceView,status_code=202,tags=['Orders'])
async def checkout(data:Checkout,request:Request,response:Response,
                   idempotency_key:Annotated[UUID,Header(alias='Idempotency-Key')],user:User=Depends(customer)):
    result=await accept_order(user.id,str(idempotency_key),data,request.state.request_id)
    response.headers['Location']='/api/v1/orders/'+result['order_id']
    response.headers['Cache-Control']='no-store'
    return result

@router.get('/orders',response_model=Page[OrderView],tags=['Orders'])
async def orders(page:PageNumber=1,page_size:Size=20,status:Status|None=None,user:User=Depends(customer)):
    stmt=select(Order).where(Order.customer_id==user.id).order_by(Order.created_at.desc(),Order.id)
    if status: stmt=stmt.where(Order.status==status)
    async with Session() as s: return await order_page(s,stmt,page,page_size)

@router.get('/orders/{order_id}',response_model=DetailView,tags=['Orders'])
async def detail(order_id:str,user:User=Depends(current_user)):
    async with Session() as s: return await order_detail(s,await accessible_order(s,order_id,user))

@router.get('/orders/{order_id}/history',response_model=Page[HistoryView],tags=['Orders'])
async def history(order_id:str,page:PageNumber=1,page_size:Size=100,user:User=Depends(current_user)):
    async with Session() as s:
        await accessible_order(s,order_id,user)
        return await paginate(s,select(History).where(History.order_id==order_id).order_by(History.version),page,page_size)

@router.get('/orders/{order_id}/notifications',response_model=Page[NotificationView],tags=['Notifications'])
async def order_notifications(order_id:str,page:PageNumber=1,page_size:Size=20,user:User=Depends(current_user)):
    async with Session() as s:
        await accessible_order(s,order_id,user)
        return await paginate(s,select(Notification).where(Notification.order_id==order_id).order_by(Notification.order_version,Notification.created_at),page,page_size)

@router.get('/notifications',response_model=Page[NotificationView],tags=['Notifications'])
async def notifications(page:PageNumber=1,page_size:Size=20,user:User=Depends(customer)):
    async with Session() as s:
        return await paginate(s,select(Notification).where(Notification.customer_id==user.id).order_by(Notification.created_at.desc(),Notification.id),page,page_size)

@router.get('/admin/orders',response_model=Page[OrderView],tags=['Administration'])
async def all_orders(page:PageNumber=1,page_size:Size=20,status:Status|None=None,user:User=Depends(admin)):
    stmt=select(Order).order_by(Order.created_at.desc(),Order.id)
    if status: stmt=stmt.where(Order.status==status)
    async with Session() as s: return await order_page(s,stmt,page,page_size)

@router.get('/admin/summary',response_model=SummaryView,tags=['Administration'])
async def summary(user:User=Depends(admin)):
    async with Session() as s:
        counts={x.value:0 for x in Status}
        counts.update(dict((await s.execute(select(Order.status,func.count()).group_by(Order.status))).all()))
        pending=await s.scalar(select(func.count()).select_from(Outbox).where(Outbox.state!='SENT'))
        oldest=await s.scalar(select(func.min(Outbox.created_at)).where(Outbox.state!='SENT'))
        retries=await s.scalar(select(func.count()).select_from(RetryJob).where(RetryJob.state.not_in(['DONE','QUARANTINED'])))
        quarantined=await s.scalar(select(func.count()).select_from(Quarantine))
        from app.models.entities import utcnow
        return {'total_orders':sum(counts.values()),'status_counts':counts,'pending_outbox':pending,
                'oldest_pending_outbox_seconds':max(0,(utcnow()-oldest).total_seconds()) if oldest else 0,
                'retry_jobs':retries,'quarantined_events':quarantined}

@router.get('/admin/quarantine',tags=['Administration'])
async def quarantines(page:PageNumber=1,page_size:Size=20,user:User=Depends(admin)):
    async with Session() as s:
        result=await paginate(s,select(Quarantine).order_by(Quarantine.created_at.desc()),page,page_size)
        # Raw malformed messages may contain sensitive text; inspect original via privileged DB access.
        for r in result['items']: r.pop('original',None)
        return result

@router.get('/admin/payments',response_model=Page[PaymentRecordView],tags=['Administration'])
async def admin_payments(page:PageNumber=1,page_size:Size=20,status:str|None=None,user:User=Depends(admin)):
    """Simulated payment records. No card or bank data exists in any table."""
    stmt=select(Payment).order_by(Payment.created_at.desc(),Payment.id)
    if status: stmt=stmt.where(Payment.status==status)
    async with Session() as s:
        total=await s.scalar(select(func.count()).select_from(stmt.subquery()))
        rows=(await s.scalars(stmt.offset((page-1)*page_size).limit(page_size))).all()
        return {'items':[{'id':p.id,'order_id':p.order_id,'amount_minor':p.amount_minor,
            'currency':(await s.scalar(select(Order.currency).where(Order.id==p.order_id))) or 'INR',
            'status':p.status,'idempotency_key':p.idempotency_key,'created_at':p.created_at}
            for p in rows],'page':page,'page_size':page_size,'total':total or 0}

@router.get('/admin/drivers',tags=['Administration'])
async def admin_drivers(user:User=Depends(admin)):
    async with Session() as s:
        rows=(await s.execute(select(Driver,func.count(Assignment.id)).outerjoin(Assignment,Assignment.driver_id==Driver.id).group_by(Driver.id).order_by(Driver.name))).all()
        items=[{'id':d.id,'name':d.name,'vehicle':d.vehicle,'active':d.active,'assigned_orders':n} for d,n in rows]
        # Wrapped in an object: the web client parses every payload as a JSON
        # object, so a bare array would be rejected as an unreadable response.
        return {'items':items,'total':len(items)}

@router.get('/admin/stuck',response_model=Page[StuckOrderView],tags=['Administration'])
async def admin_stuck(page:PageNumber=1,page_size:Size=20,older_than_seconds:int=120,user:User=Depends(admin)):
    """Orders that have not advanced. A long PENDING order usually means a broker outage."""
    from app.models.entities import utcnow
    cutoff=utcnow()-timedelta(seconds=max(1,older_than_seconds))
    stmt=select(Order,Restaurant.name).join(Restaurant,Restaurant.id==Order.restaurant_id).where(Order.status=='PENDING',Order.created_at<=cutoff).order_by(Order.created_at)
    async with Session() as s:
        total=await s.scalar(select(func.count()).select_from(stmt.subquery()))
        rows=(await s.execute(stmt.offset((page-1)*page_size).limit(page_size))).all()
        now=utcnow()
        return {'items':[{'id':o.id,'customer_id':o.customer_id,'restaurant_name':rn,'status':o.status,
            'total_minor':o.total_amount_minor,'currency':o.currency,'version':o.version,
            'age_seconds':max(0,(now-o.created_at).total_seconds())} for o,rn in rows],
            'page':page,'page_size':page_size,'total':total or 0}

@router.get('/admin/analytics',response_model=AnalyticsView,tags=['Administration'])
async def admin_analytics(days:int=30,user:User=Depends(admin)):
    from app.models.entities import utcnow
    window=max(1,min(days,365))
    since=utcnow()-timedelta(days=window)
    async with Session() as s:
        rows=(await s.execute(select(Order.status,Order.total_amount_minor,Order.created_at,Restaurant.name)
            .join(Restaurant,Restaurant.id==Order.restaurant_id).where(Order.created_at>=since))).all()
    total=len(rows)
    settled={'PAID','CONFIRMED','DRIVER_ASSIGNED'}
    failed={'PAYMENT_FAILED','FAILED'}
    gross=sum(r[1] for r in rows)
    settled_minor=sum(r[1] for r in rows if r[0] in settled)
    failed_minor=sum(r[1] for r in rows if r[0] in failed)
    counts={}
    for st,_m,_d,_r in rows: counts[st]=counts.get(st,0)+1
    daily={}
    for _st,m,d,_r in rows:
        key=d.date().isoformat()
        slot=daily.setdefault(key,{'day':key,'orders':0,'revenue_minor':0})
        slot['orders']+=1
        if _st in settled: slot['revenue_minor']+=m
    by_rest={}
    for st,m,_d,rn in rows:
        slot=by_rest.setdefault(rn,{'restaurant':rn,'orders':0,'revenue_minor':0})
        slot['orders']+=1
        if st in settled: slot['revenue_minor']+=m
    return {'total_orders':total,'gross_minor':gross,'settled_minor':settled_minor,'failed_minor':failed_minor,
        'average_order_minor':int(gross/total) if total else 0,
        'failure_rate':round(len([r for r in rows if r[0] in failed])/total,4) if total else 0.0,
        'completion_rate':round(len([r for r in rows if r[0]=='DRIVER_ASSIGNED'])/total,4) if total else 0.0,
        'daily':[daily[k] for k in sorted(daily)][-window:],
        'top_restaurants':sorted(by_rest.values(),key=lambda x:-x['revenue_minor'])[:10],
        'status_mix':[{'status':k,'count':counts[k]} for k in sorted(counts,key=lambda x:-counts[x])]}

@router.post('/admin/quarantine/{record_id}/acknowledge',tags=['Administration'])
async def acknowledge_quarantine(record_id:str,user:User=Depends(admin)):
    """Operator triage flag only. Never requeues or reprocesses the event."""
    from app.models.entities import utcnow
    async with Session() as s, s.begin():
        record=await s.scalar(select(Quarantine).where(Quarantine.id==record_id).with_for_update())
        if record is None: raise ApiError(404,'NOT_FOUND','That quarantined event no longer exists.')
        if record.acknowledged:
            return {'id':record.id,'acknowledged':True,'acknowledged_at':record.acknowledged_at,'acknowledged_by':record.acknowledged_by}
        record.acknowledged,record.acknowledged_at,record.acknowledged_by=True,utcnow(),user.id
    return {'id':record.id,'acknowledged':True,'acknowledged_at':record.acknowledged_at,'acknowledged_by':record.acknowledged_by}

@router.post('/admin/orders/{order_id}/cancel',tags=['Administration'])
async def admin_cancel_order(order_id:str,reason:str='GOODWILL',user:User=Depends(admin)):
    """Cancels an order and records what is owed.

    Admin may cancel anything not yet terminal. Because QuickBite settles no
    real money, cancellation writes a refund obligation rather than moving
    funds: the amount is what a real gateway would need to return.
    """
    from app.models.entities import utcnow
    from app.domain.state import TERMINAL
    if reason not in {'RESTAURANT_REJECTED','RESTAURANT_UNAVAILABLE','CUSTOMER_CANCELLED','DUPLICATE_ORDER','GOODWILL'}:
        raise ApiError(422,'INVALID_INPUT','That cancellation reason is not recognised.')
    async with Session() as s,s.begin():
        order=await s.scalar(select(Order).where(Order.id==order_id).with_for_update())
        if order is None: raise ApiError(404,'NOT_FOUND','Order not found.')
        if order.status in TERMINAL:
            raise ApiError(409,'ALREADY_TERMINAL',f'This order already ended as {order.status} and cannot be cancelled.')
        settled=order.status in {'PAID','CONFIRMED'}
        payment=await s.scalar(select(Payment).where(Payment.order_id==order.id))
        existing=await s.scalar(select(Refund).where(Refund.order_id==order.id))
        if existing is None and payment is not None:
            s.add(Refund(order_id=order.id,payment_id=payment.id,amount_minor=order.total_amount_minor,
                         currency=order.currency,reason=reason,status='PENDING'))
        if settled:
            order.status=Status.FAILED; order.version+=1; order.updated_at=utcnow()
            order.failure_code='ADMIN_CANCELLED'
            s.add(History(order_id=order.id,status=Status.FAILED,version=order.version,
                          event_id=f'admin-cancel-{order.id}',failure_code='ADMIN_CANCELLED'))
        else:
            # Still PENDING: stop it before payment settles by marking it failed.
            order.status=Status.PAYMENT_FAILED; order.version+=1; order.updated_at=utcnow()
            order.failure_code='ADMIN_CANCELLED'
            s.add(History(order_id=order.id,status=Status.PAYMENT_FAILED,version=order.version,
                          event_id=f'admin-cancel-{order.id}',failure_code='ADMIN_CANCELLED'))
    return {'id':order.id,'status':order.status,'refund_required':settled,'reason':reason}

@router.post('/admin/quarantine/{record_id}/requeue',tags=['Administration'])
async def admin_requeue(record_id:str,user:User=Depends(admin)):
    """Requeues one quarantined event for processing.

    Guarded so it cannot double-process an order: the quarantine record is
    deleted and a fresh event is inserted in a single transaction, and the
    consumer's dedup table is cleared for that event first. Re-running is
    rejected once the record is gone.
    """
    from app.models.entities import utcnow
    from app.messaging.events import Event
    from app.domain.state import EXPECTED
    async with Session() as s,s.begin():
        record=await s.scalar(select(Quarantine).where(Quarantine.id==record_id).with_for_update())
        if record is None: raise ApiError(404,'NOT_FOUND','That quarantined event no longer exists.')
        consumer=record.consumer_name
        if consumer not in EXPECTED:
            raise ApiError(409,'NOT_REQUEUEABLE','That consumer has no processing path to requeue into.')
        original=record.original or {}
        order=await s.scalar(select(Order).where(Order.id==original.get('order_id')))
        if order is None:
            order=await s.scalar(select(Order).order_by(Order.created_at.desc()))
        if order is None: raise ApiError(409,'NOT_REQUEUEABLE','No order is associated with that event.')
        # Clearing dedup is required, otherwise the consumer treats it as done
        # and the requeue silently does nothing.
        await s.execute(delete(ProcessedEvent).where(ProcessedEvent.consumer_name==consumer,
                                                      ProcessedEvent.event_id==record.event_id))
        await s.execute(delete(RetryJob).where(RetryJob.consumer_name==consumer,
                                               RetryJob.event_id==record.event_id))
        event=Event(event_id=record.event_id,schema_version=1,
                    event_type=original.get('event_type') or EXPECTED[consumer][0],
                    order_id=order.id,order_version=order.version,occurred_at=utcnow(),
                    correlation_id=original.get('correlation_id','admin-requeue'),
                    causation_id=record.id,data=original.get('data') or {})
        # The original publication already owns its outbox primary key, so a
        # replay needs its own row rather than re-inserting domain:<event_id>.
        s.add(Outbox(id=f'requeue:{record.id}',event_id=event.event_id,
                     payload=event.model_dump(mode='json'),exchange='quickbite.orders',
                     routing_key=event.event_type))
        await s.delete(record)
    return {'requeued':True,'consumer':consumer,'event_id':record.event_id,'order_id':order.id}

@router.get('/admin/system',tags=['Administration'])
async def system(user:User=Depends(admin)):
    cfg=settings()
    try:
        async with httpx.AsyncClient(timeout=2) as client:
            r=await client.get(cfg.rabbitmq_management_url+'/api/queues/%2F',auth=(cfg.rabbitmq_user,cfg.rabbitmq_password))
            r.raise_for_status()
            queues=[{k:q.get(k,0) for k in ['name','messages','messages_ready','messages_unacknowledged','consumers']} for q in r.json()]
        return {'broker':'connected','queues':queues}
    except Exception:
        return {'broker':'unavailable','queues':[],'message':'Orders remain durable in the PostgreSQL outbox.'}
