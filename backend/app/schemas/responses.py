from datetime import datetime
from typing import Generic,TypeVar,Literal
from pydantic import BaseModel,Field
T=TypeVar('T')
class Page(BaseModel,Generic[T]):
    items:list[T]
    page:int
    page_size:int
    total:int
class UserView(BaseModel):
    id:str
    email:str
    name:str
    role:Literal['CUSTOMER','ADMIN']
class TokenView(BaseModel):
    access_token:str
    token_type:str
    expires_at:datetime
    expires_in:int
    role:str
    user:UserView
class RestaurantView(BaseModel):
    id:str
    name:str
    cuisine:str
    description:str
    image:str
    available:bool
    rating_tenths:int
    eta_minutes:int
class MenuItemView(BaseModel):
    id:str
    restaurant_id:str
    name:str
    description:str
    image:str
    price_minor:int
    currency:str
    available:bool
    vegetarian:bool
class MenuPage(Page[MenuItemView]):
    restaurant:RestaurantView
    # Echoes the active filters so a client can restore exactly this view.
    # Declared here because response_model drops undeclared fields.
    filters:dict=Field(default_factory=dict)
class CatalogView(BaseModel):
    total_restaurants:int
    cuisines:list[str]
    restaurants:list[RestaurantView]
    dishes:list[MenuItemView]
class AcceptanceView(BaseModel):
    order_id:str
    status:Literal['PENDING']
    currency:str
    total_amount_minor:int
    version:int
    message:str
class OrderView(BaseModel):
    id:str
    customer_id:str
    restaurant_id:str
    restaurant_name:str|None=None
    currency:str
    total_amount_minor:int
    status:str
    version:int
    failure_code:str|None
    driver_id:str|None
    created_at:datetime
    updated_at:datetime
class ItemView(BaseModel):
    id:str
    order_id:str
    menu_item_id:str
    item_name:str
    quantity:int
    unit_price_minor:int
class HistoryView(BaseModel):
    id:str
    order_id:str
    status:str
    version:int
    event_id:str
    failure_code:str|None
    created_at:datetime
class DriverView(BaseModel):
    id:str
    name:str
    vehicle:str
    active:bool
class DetailView(OrderView):
    delivery_address:str
    restaurant:RestaurantView
    items:list[ItemView]
    history:list[HistoryView]
    driver:DriverView|None
    failure_message:str|None
class NotificationView(BaseModel):
    id:str
    customer_id:str
    order_id:str
    event_id:str
    order_version:int
    title:str
    message:str
    created_at:datetime
class SummaryView(BaseModel):
    total_orders:int
    status_counts:dict[str,int]
    pending_outbox:int
    oldest_pending_outbox_seconds:float
    retry_jobs:int
    quarantined_events:int
class PaymentRecordView(BaseModel):
    id:str
    order_id:str
    amount_minor:int
    currency:str
    status:str
    idempotency_key:str
    created_at:datetime
class DriverView(BaseModel):
    id:str
    name:str
    vehicle:str
    active:bool
    assigned_orders:int
class StuckOrderView(BaseModel):
    id:str
    customer_id:str
    restaurant_name:str
    status:str
    total_minor:int
    currency:str
    age_seconds:float
    version:int
class AnalyticsView(BaseModel):
    total_orders:int
    gross_minor:int
    settled_minor:int
    failed_minor:int
    average_order_minor:int
    failure_rate:float
    completion_rate:float
    daily:list[dict]
    top_restaurants:list[dict]
    status_mix:list[dict]

class ErrorView(BaseModel):
    code:str
    message:str
    details:dict=Field(default_factory=dict)
    request_id:str
