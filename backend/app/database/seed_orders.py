"""Seed 200 historical demo orders so the admin dashboard has sample data.

Development only, blocked in production, and safe to re-run: it fills missing
demo order IDs up to the 200-order target. Never touches real accounts or their passwords.

Usage: python -m app.database.seed_orders
"""
import asyncio
import random
from sqlalchemy import select
from app.database.session import Session, engine
from app.models.entities import (
    User, Restaurant, MenuItem, Order, OrderItem, History,
    Payment, Assignment, Driver,
)
from app.config.settings import settings

TARGET = 200
MARKER = 'QB-DEMO-'

# Weighted so the resulting chart shows a realistic funnel rather than a flat
# split: most orders complete, a minority fail.
TERMINAL = (
    ['DRIVER_ASSIGNED'] * 58
    + ['CONFIRMED'] * 12
    + ['PAID'] * 6
    + ['PAYMENT_FAILED'] * 14
    + ['FAILED'] * 10
)


async def seed_orders() -> None:
    if settings().app_env == 'production':
        raise RuntimeError('Demo order seeds are forbidden in production')

    rng = random.Random(20261017)
    now = await _now()

    async with Session() as s:
        existing_ids = set((await s.scalars(
            select(Order.id).where(Order.id.like(f'{MARKER}%'))
        )).all())
        missing = [n for n in range(1, TARGET + 1) if f'{MARKER}{n:04d}' not in existing_ids]
        if not missing:
            print(f'Skipped: {TARGET} demo orders already present. Existing data preserved.')
            await engine.dispose()
            return

        customers = (await s.scalars(select(User).where(User.role == 'CUSTOMER'))).all()
        restaurants = (await s.scalars(select(Restaurant))).all()
        drivers = (await s.scalars(select(Driver))).all()
        if not customers or not restaurants:
            print('Skipped: run the main seed first (python -m app.database.seed).')
            await engine.dispose()
            return
        menu_by_restaurant: dict[str, list[MenuItem]] = {}
        for item in (await s.scalars(select(MenuItem))).all():
            menu_by_restaurant.setdefault(item.restaurant_id, []).append(item)

    created = 0
    async with Session() as s, s.begin():
        for n in missing:
            customer = rng.choice(customers)
            restaurant = rng.choice(restaurants)
            options = menu_by_restaurant.get(restaurant.id) or []
            if not options:
                continue
            status = rng.choice(TERMINAL)
            chosen = rng.sample(options, k=min(len(options), rng.randint(1, 3)))
            lines, total = [], 0
            for item in chosen:
                quantity = rng.randint(1, 4)
                total += item.price_minor * quantity
                lines.append((item.id, item.name, quantity, item.price_minor))

            # Spread orders across the past 29 days, weighted toward recent days.
            day_offset = min(29, int(abs(rng.gauss(0, 11))))
            created_at = _shift(now, -day_offset, rng)

            order = Order(
                id=f'{MARKER}{n:04d}',
                customer_id=customer.id,
                restaurant_id=restaurant.id,
                delivery_address=f'{rng.randint(1, 240)} Demo Street, QuickBite City',
                currency='INR',
                total_amount_minor=total,
                status=status,
                version=_version_for(status),
                created_at=created_at,
                updated_at=created_at,
            )
            if status in {'PAYMENT_FAILED', 'FAILED'}:
                order.failure_code = (
                    'PAYMENT_DECLINED' if status == 'PAYMENT_FAILED' else 'RESTAURANT_UNAVAILABLE'
                )
            s.add(order)
            await s.flush()

            for menu_item_id, name, quantity, price in lines:
                s.add(OrderItem(order_id=order.id, menu_item_id=menu_item_id, item_name=name,
                                quantity=quantity, unit_price_minor=price))

            # Append-only history, mirroring the real worker's transitions.
            # Version is unique per order, so it is the step index rather than a
            # per-status constant.
            for index, (step, at) in enumerate(_history_for(status, created_at), start=1):
                s.add(History(order_id=order.id, status=step, version=index,
                              event_id=f'{MARKER}evt-{n:04d}-{step.lower()}', created_at=at))

            if status in {'PAID', 'CONFIRMED', 'DRIVER_ASSIGNED'}:
                s.add(Payment(order_id=order.id, amount_minor=total, status='SIMULATED',
                              idempotency_key=f'{MARKER}pay-{n:04d}', created_at=created_at))
            if status == 'DRIVER_ASSIGNED' and drivers:
                driver = rng.choice(drivers)
                order.driver_id = driver.id
                s.add(Assignment(order_id=order.id, driver_id=driver.id, created_at=created_at))
            created += 1

    print(f'Seed complete: {created} historical demo orders added, up to {TARGET} total. '
          'No accounts, passwords or real orders were modified.')
    await engine.dispose()


def _version_for(status: str) -> int:
    return {'PENDING': 1, 'PAID': 2, 'CONFIRMED': 3, 'DRIVER_ASSIGNED': 4,
            'PAYMENT_FAILED': 1, 'FAILED': 3}[status]


def _version_of(status: str) -> int:
    """Terminal order version, used for the order row itself."""
    return {'PENDING': 1, 'PAID': 2, 'CONFIRMED': 3, 'DRIVER_ASSIGNED': 4,
            'PAYMENT_FAILED': 1, 'FAILED': 3}[status]


def _history_for(status: str, created_at):
    steps = ['PENDING']
    if status == 'PAYMENT_FAILED':
        steps.append('PAYMENT_FAILED')
    elif status == 'FAILED':
        steps += ['PAID', 'CONFIRMED', 'FAILED']
    elif status in {'PAID', 'CONFIRMED', 'DRIVER_ASSIGNED'}:
        steps += ['PAID']
        if status in {'CONFIRMED', 'DRIVER_ASSIGNED'}:
            steps.append('CONFIRMED')
        if status == 'DRIVER_ASSIGNED':
            steps.append('DRIVER_ASSIGNED')
    from datetime import timedelta
    return [(step, created_at + timedelta(seconds=120 * i)) for i, step in enumerate(steps)]


def _shift(base, days: int, rng: random.Random):
    from datetime import timedelta
    return base + timedelta(days=days, seconds=rng.randint(0, 86_399))


async def _now():
    from app.models.entities import utcnow
    return utcnow()


if __name__ == '__main__':
    asyncio.run(seed_orders())
