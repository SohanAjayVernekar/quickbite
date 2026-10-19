from sqlalchemy import select, func
from app.models.entities import Order, Restaurant, OrderItem, History, Driver
from app.domain.state import FAILURES
from app.api.errors import ApiError

def row_dict(row): return {c.name:getattr(row,c.name) for c in row.__table__.columns}
async def paginate(s,statement,page,page_size):
    total=await s.scalar(select(func.count()).select_from(statement.order_by(None).subquery()))
    items=(await s.scalars(statement.offset((page-1)*page_size).limit(page_size))).all()
    return {'items':[row_dict(x) for x in items],'page':page,'page_size':page_size,'total':total}
async def accessible_order(s,order_id,user):
    order=await s.get(Order,order_id)
    if not order or (user.role!='ADMIN' and order.customer_id!=user.id):
        raise ApiError(404,'ORDER_NOT_FOUND','Order not found.')
    return order
async def order_detail(s,order):
    result=row_dict(order)
    result['restaurant']=row_dict(await s.get(Restaurant,order.restaurant_id))
    result['items']=[row_dict(x) for x in (await s.scalars(select(OrderItem).where(OrderItem.order_id==order.id))).all()]
    result['history']=[row_dict(x) for x in (await s.scalars(select(History).where(History.order_id==order.id).order_by(History.version))).all()]
    result['driver']=row_dict(await s.get(Driver,order.driver_id)) if order.driver_id else None
    result['failure_message']=FAILURES.get(order.failure_code,'Processing could not be completed.') if order.failure_code else None
    return result
async def order_page(s,statement,page,page_size):
    result=await paginate(s,statement,page,page_size)
    ids={r['restaurant_id'] for r in result['items']}
    names={r.id:r.name for r in (await s.scalars(select(Restaurant).where(Restaurant.id.in_(ids)))).all()} if ids else {}
    for row in result['items']:
        row.pop('delivery_address',None)
        row['restaurant_name']=names.get(row['restaurant_id'],'Restaurant')
    return result
