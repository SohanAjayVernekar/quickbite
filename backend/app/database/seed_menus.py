"""Sync every kitchen's menu up to DISHES_PER_KITCHEN entries.

Existing dishes keep their IDs, prices and availability. Only missing slots are
appended, so no order ever references a removed or repriced row.

Usage: python -m app.database.seed_menus
"""
import asyncio
from sqlalchemy import select, func
from app.database.session import Session, engine
from app.models.entities import Restaurant, MenuItem
from app.config.settings import settings
from app.database.catalog import CATALOG, DISHES_PER_KITCHEN


async def seed_menus() -> None:
    if settings().app_env == 'production':
        raise RuntimeError('Demo menu seeds are forbidden in production')

    catalogue = {k.id: k for k in CATALOG}
    added = 0
    async with Session() as s:
        kitchens = (await s.scalars(select(Restaurant))).all()
        counts: dict[str, int] = {}
        for item in (await s.scalars(select(MenuItem))).all():
            counts[item.restaurant_id] = counts.get(item.restaurant_id, 0) + 1

    async with Session() as s, s.begin():
        for restaurant in kitchens:
            kitchen = catalogue.get(restaurant.id)
            if kitchen is None:
                continue
            have = counts.get(restaurant.id, 0)
            if have >= DISHES_PER_KITCHEN:
                continue
            # Seed IDs are positional (kitchen-N-M), so the next free slot is
            # the current count. Append only; never rewrite existing rows.
            for index, dish in enumerate(kitchen.menu, start=1):
                if index <= have:
                    continue
                await s.merge(MenuItem(
                    id=f'{restaurant.id}-{index}',
                    restaurant_id=restaurant.id,
                    name=dish.name,
                    description=dish.description,
                    image=dish.image,
                    price_minor=dish.price,
                    currency='INR',
                    available=dish.available,
                    vegetarian=dish.vegetarian,
                ))
                added += 1

    async with Session() as s:
        total = await s.scalar(select(func.count()).select_from(MenuItem))
        per_kitchen = await s.scalar(
            select(func.count())
            .select_from(MenuItem)
            .group_by(MenuItem.restaurant_id)
            .order_by(func.count())
            .limit(1)
        )
    print(f'Seed complete: {added} dishes appended, {total} dishes total, '
          f'minimum {per_kitchen} per kitchen (target {DISHES_PER_KITCHEN}). '
          'Existing dishes kept their IDs, prices and availability.')
    await engine.dispose()


if __name__ == '__main__':
    asyncio.run(seed_menus())
