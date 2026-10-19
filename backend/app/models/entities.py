from datetime import datetime, timezone
from uuid import uuid4
from sqlalchemy import String, Integer, BigInteger, Boolean, DateTime, ForeignKey, UniqueConstraint, CheckConstraint, Text
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.orm import DeclarativeBase, Mapped, mapped_column

def uid(): return str(uuid4())
def utcnow(): return datetime.now(timezone.utc)
class Base(DeclarativeBase): pass
class TimeMixin:
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow)
class User(Base, TimeMixin):
    __tablename__='users'
    id: Mapped[str] = mapped_column(String(64), primary_key=True, default=uid)
    email: Mapped[str] = mapped_column(String(254), unique=True)
    name: Mapped[str] = mapped_column(String(100))
    password_hash: Mapped[str] = mapped_column(Text)
    role: Mapped[str] = mapped_column(String(20))
    active: Mapped[bool] = mapped_column(Boolean, default=True)
    __table_args__=(CheckConstraint("role IN ('CUSTOMER','ADMIN')"),)
class Restaurant(Base):
    __tablename__='restaurants'
    id: Mapped[str] = mapped_column(String(64), primary_key=True)
    name: Mapped[str] = mapped_column(String(120))
    cuisine: Mapped[str] = mapped_column(String(80))
    description: Mapped[str] = mapped_column(Text)
    image: Mapped[str] = mapped_column(String(200))
    available: Mapped[bool] = mapped_column(Boolean, default=True)
    rating_tenths: Mapped[int] = mapped_column(Integer, default=47)
    eta_minutes: Mapped[int] = mapped_column(Integer, default=30)
class MenuItem(Base):
    __tablename__='menu_items'
    id: Mapped[str] = mapped_column(String(64), primary_key=True)
    restaurant_id: Mapped[str] = mapped_column(ForeignKey('restaurants.id'), index=True)
    name: Mapped[str] = mapped_column(String(120))
    description: Mapped[str] = mapped_column(Text)
    image: Mapped[str] = mapped_column(String(200))
    price_minor: Mapped[int] = mapped_column(BigInteger)
    currency: Mapped[str] = mapped_column(String(3), default='INR')
    available: Mapped[bool] = mapped_column(Boolean, default=True)
    vegetarian: Mapped[bool] = mapped_column(Boolean, default=True)
    __table_args__=(CheckConstraint('price_minor >= 0'),)
class Driver(Base):
    __tablename__='drivers'
    id: Mapped[str] = mapped_column(String(64), primary_key=True)
    name: Mapped[str] = mapped_column(String(100))
    vehicle: Mapped[str] = mapped_column(String(100))
    active: Mapped[bool] = mapped_column(Boolean, default=True)
class Order(Base, TimeMixin):
    __tablename__='orders'
    id: Mapped[str] = mapped_column(String(64), primary_key=True)
    customer_id: Mapped[str] = mapped_column(ForeignKey('users.id'), index=True)
    restaurant_id: Mapped[str] = mapped_column(ForeignKey('restaurants.id'))
    delivery_address: Mapped[str] = mapped_column(String(500))
    currency: Mapped[str] = mapped_column(String(3))
    total_amount_minor: Mapped[int] = mapped_column(BigInteger)
    status: Mapped[str] = mapped_column(String(32), index=True)
    version: Mapped[int] = mapped_column(Integer, default=1)
    failure_code: Mapped[str | None] = mapped_column(String(80))
    driver_id: Mapped[str | None] = mapped_column(ForeignKey('drivers.id'))
    updated_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow)
    __table_args__=(CheckConstraint('total_amount_minor >= 0'), CheckConstraint('version >= 1'),
        CheckConstraint("status IN ('PENDING','PAID','CONFIRMED','DRIVER_ASSIGNED','PAYMENT_FAILED','FAILED')"))
class OrderItem(Base):
    __tablename__='order_items'
    id: Mapped[str] = mapped_column(String(64), primary_key=True, default=uid)
    order_id: Mapped[str] = mapped_column(ForeignKey('orders.id'), index=True)
    menu_item_id: Mapped[str] = mapped_column(ForeignKey('menu_items.id'))
    item_name: Mapped[str] = mapped_column(String(120))
    quantity: Mapped[int] = mapped_column(Integer)
    unit_price_minor: Mapped[int] = mapped_column(BigInteger)
    __table_args__=(UniqueConstraint('order_id','menu_item_id'),CheckConstraint('quantity BETWEEN 1 AND 20'),CheckConstraint('unit_price_minor >= 0'))
class History(Base, TimeMixin):
    __tablename__='order_status_history'
    id: Mapped[str] = mapped_column(String(64), primary_key=True, default=uid)
    order_id: Mapped[str] = mapped_column(ForeignKey('orders.id'), index=True)
    status: Mapped[str] = mapped_column(String(32))
    version: Mapped[int] = mapped_column(Integer)
    event_id: Mapped[str] = mapped_column(String(64))
    failure_code: Mapped[str | None] = mapped_column(String(80))
    __table_args__=(UniqueConstraint('order_id','version'),)
class Idempotency(Base, TimeMixin):
    __tablename__='idempotency_records'
    customer_id: Mapped[str] = mapped_column(ForeignKey('users.id'), primary_key=True)
    key: Mapped[str] = mapped_column(String(36), primary_key=True)
    request_hash: Mapped[str] = mapped_column(String(64))
    order_id: Mapped[str] = mapped_column(ForeignKey('orders.id'), unique=True)
    response: Mapped[dict] = mapped_column(JSONB)
class Payment(Base, TimeMixin):
    __tablename__='simulated_payments'
    id: Mapped[str] = mapped_column(String(64), primary_key=True, default=uid)
    order_id: Mapped[str] = mapped_column(ForeignKey('orders.id'), unique=True)
    amount_minor: Mapped[int] = mapped_column(BigInteger)
    status: Mapped[str] = mapped_column(String(20))
    idempotency_key: Mapped[str] = mapped_column(String(100), unique=True)
class Assignment(Base, TimeMixin):
    __tablename__='driver_assignments'
    id: Mapped[str] = mapped_column(String(64), primary_key=True, default=uid)
    order_id: Mapped[str] = mapped_column(ForeignKey('orders.id'), unique=True)
    driver_id: Mapped[str] = mapped_column(ForeignKey('drivers.id'))
class Notification(Base, TimeMixin):
    __tablename__='notifications'
    id: Mapped[str] = mapped_column(String(64), primary_key=True, default=uid)
    customer_id: Mapped[str] = mapped_column(ForeignKey('users.id'), index=True)
    order_id: Mapped[str] = mapped_column(ForeignKey('orders.id'), index=True)
    event_id: Mapped[str] = mapped_column(String(64))
    order_version: Mapped[int] = mapped_column(Integer)
    title: Mapped[str] = mapped_column(String(150))
    message: Mapped[str] = mapped_column(Text)
    __table_args__=(UniqueConstraint('customer_id','event_id'),)
class ProcessedEvent(Base, TimeMixin):
    __tablename__='processed_events'
    consumer_name: Mapped[str] = mapped_column(String(32), primary_key=True)
    event_id: Mapped[str] = mapped_column(String(64), primary_key=True)
    result: Mapped[str] = mapped_column(String(32))
class Outbox(Base, TimeMixin):
    __tablename__='outbox_events'
    id: Mapped[str] = mapped_column(String(160), primary_key=True)
    event_id: Mapped[str] = mapped_column(String(64), index=True)
    payload: Mapped[dict] = mapped_column(JSONB)
    exchange: Mapped[str] = mapped_column(String(80))
    routing_key: Mapped[str] = mapped_column(String(100))
    headers: Mapped[dict] = mapped_column(JSONB, default=dict)
    state: Mapped[str] = mapped_column(String(20), default='PENDING', index=True)
    available_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow, index=True)
    sent_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    publish_attempts: Mapped[int] = mapped_column(Integer, default=0)
    last_error: Mapped[str | None] = mapped_column(String(100))
class RetryJob(Base, TimeMixin):
    __tablename__='retry_jobs'
    id: Mapped[str] = mapped_column(String(64), primary_key=True, default=uid)
    consumer_name: Mapped[str] = mapped_column(String(32))
    event_id: Mapped[str] = mapped_column(String(64))
    attempt: Mapped[int] = mapped_column(Integer)
    outbox_id: Mapped[str] = mapped_column(ForeignKey('outbox_events.id'), unique=True)
    due_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), index=True)
    state: Mapped[str] = mapped_column(String(20), default='SCHEDULED', index=True)
    failure_code: Mapped[str] = mapped_column(String(80))
    __table_args__=(UniqueConstraint('consumer_name','event_id','attempt'),CheckConstraint('attempt BETWEEN 1 AND 3'))
class Quarantine(Base, TimeMixin):
    __tablename__='quarantine_records'
    id: Mapped[str] = mapped_column(String(64), primary_key=True, default=uid)
    consumer_name: Mapped[str] = mapped_column(String(32))
    event_id: Mapped[str] = mapped_column(String(64))
    source_queue: Mapped[str] = mapped_column(String(100))
    original: Mapped[dict] = mapped_column(JSONB)
    attempts: Mapped[int] = mapped_column(Integer)
    failure_code: Mapped[str] = mapped_column(String(80))
    reason: Mapped[str] = mapped_column(String(300))
    acknowledged: Mapped[bool] = mapped_column(Boolean, default=False, index=True)
    acknowledged_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    acknowledged_by: Mapped[str | None] = mapped_column(String(64))
    __table_args__=(UniqueConstraint('consumer_name','event_id'),)
class Refund(Base, TimeMixin):
    """An obligation to return funds for a settled order.

    QuickBite settles no real money, so this records intent rather than moving
    funds. It exists so a future rejection or cancellation path has somewhere
    to record what is owed instead of silently ending at FAILED.
    """
    __tablename__='refund_records'
    id: Mapped[str] = mapped_column(String(64), primary_key=True, default=uid)
    order_id: Mapped[str] = mapped_column(ForeignKey('orders.id'), unique=True)
    payment_id: Mapped[str | None] = mapped_column(ForeignKey('simulated_payments.id'))
    amount_minor: Mapped[int] = mapped_column(BigInteger)
    currency: Mapped[str] = mapped_column(String(3))
    reason: Mapped[str] = mapped_column(String(40))
    status: Mapped[str] = mapped_column(String(20), default='PENDING', index=True)
    completed_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    __table_args__=(CheckConstraint('amount_minor >= 0'),
                    CheckConstraint("status IN ('PENDING','COMPLETED','FAILED')"),
                    CheckConstraint("reason IN ('RESTAURANT_REJECTED','RESTAURANT_UNAVAILABLE','CUSTOMER_CANCELLED','DUPLICATE_ORDER','GOODWILL')"))
class DemoCheckpoint(Base, TimeMixin):
    __tablename__='demo_checkpoints'
    service: Mapped[str] = mapped_column(String(32), primary_key=True)
    identity: Mapped[str] = mapped_column(String(160), primary_key=True)
    checkpoint: Mapped[str] = mapped_column(String(40), primary_key=True)
