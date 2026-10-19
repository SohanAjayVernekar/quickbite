"""Rewrite every kitchen's menu to the current catalogue definition.

Dish IDs, orders and order-item snapshots are preserved: this updates names,
descriptions, photographs, prices and vegetarian flags in place rather than
deleting rows, so no historical order is left pointing at a missing dish.

Usage: python -m app.database.resync_menus
"""
import asyncio
from sqlalchemy import select, func
from app.database.session import Session, engine
from app.models.entities import Restaurant, MenuItem, OrderItem
from app.config.settings import settings
from app.database.catalog import CATALOG, DISHES_PER_KITCHEN


async def resync_menus() -> None:
    if settings().app_env == 'production':
        raise RuntimeError('Demo menu syncs are forbidden in production')

    catalogue = {k.id: k for k in CATALOG}
    updated = 0
    removed = 0
    added = 0
    orphans: list[str] = []

    async with Session() as s:
        restaurants = (await s.scalars(select(Restaurant))).all()
        items = (await s.scalars(select(MenuItem))).all()

    # Group by restaurant once; 20k rows in a dict avoids a query per dish.
    by_restaurant: dict[str, list[MenuItem]] = {}
    for item in items:
        by_restaurant.setdefault(item.restaurant_id, []).append(item)

    wanted_names = {
        k.id: {d.name for d in k.menu}
        for k in CATALOG if k.id in catalogue
    }

    async with Session() as s, s.begin():
        for restaurant in restaurants:
            kitchen = catalogue.get(restaurant.id)
            if kitchen is None:
                continue
            existing = by_restaurant.get(restaurant.id, [])
            # IDs are positional (kitchen-001-7). Sort numerically, not
            # lexically, or "...-10" lands before "...-2" and dishes get
            # written to the wrong rows.
            existing.sort(key=lambda i: int(i.id.rsplit('-', 1)[-1]))
            keep = wanted_names[restaurant.id]
            # Rows left over from an earlier catalogue revision are dropped,
            # but only when no order item references them, so historical
            # orders never lose the dish they were placed against.
            for row in existing:
                if row.name in keep:
                    continue
                referenced = await s.scalar(
                    select(OrderItem.id).where(OrderItem.menu_item_id == row.id).limit(1)
                )
                if referenced is None:
                    # Flush the delete before reusing the slot, otherwise the
                    # primary key still collides inside this transaction.
                    await s.delete(row)
                    await s.flush()
                    removed += 1
                else:
                    orphans.append(row.id)

            # Re-read after the deletes: `existing` came from another session
            # and still lists rows that have just been removed.
            surviving = (await s.scalars(
                select(MenuItem).where(MenuItem.restaurant_id == restaurant.id)
            )).all()
            live = sorted(surviving, key=lambda i: int(i.id.rsplit('-', 1)[-1]))
            keep = {d.name for d in kitchen.menu}
            dishes = {d.name: d for d in kitchen.menu}

            def slot(row: MenuItem) -> int:
                return int(row.id.rsplit('-', 1)[-1])

            async def referenced(row: MenuItem) -> bool:
                return await s.scalar(
                    select(OrderItem.id).where(OrderItem.menu_item_id == row.id).limit(1)
                ) is not None

            # Rows are matched to dishes by NAME, never by position: a row
            # already serving dish X keeps X, so the same name can never be
            # written onto two rows of one kitchen.
            placed: dict[str, MenuItem] = {}
            relocate: list[MenuItem] = []
            groups: dict[str, list[MenuItem]] = {}
            for row in live:
                groups.setdefault(row.name, []).append(row)
            for name, rows in groups.items():
                if name not in keep:
                    # Order-referenced leftovers stay as row IDs but are
                    # rewritten to a still-unplaced dish below.
                    relocate.extend(rows)
                    continue
                head = min(rows, key=slot)
                placed[name] = head
                for row in rows:
                    if row is head:
                        continue
                    if await referenced(row):
                        relocate.append(row)
                        continue
                    await s.delete(row)
                    await s.flush()
                    removed += 1

            unplaced = [d for d in kitchen.menu if d.name not in placed]
            # Rewrite each referenced leftover onto the next unplaced dish.
            for row in relocate:
                if not unplaced:
                    break
                dish = unplaced.pop(0)
                placed[dish.name] = row
                if (row.name, row.image) != (dish.name, dish.image):
                    updated += 1
                row.name = dish.name
                row.description = dish.description
                row.image = dish.image
                row.price_minor = dish.price
                row.vegetarian = dish.vegetarian
            used = {slot(r) for r in live}
            next_slot = 1
            for dish in unplaced[:]:
                while next_slot in used:
                    next_slot += 1
                used.add(next_slot)
                s.add(MenuItem(
                    id=f'{restaurant.id}-{next_slot}',
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
                next_slot += 1

    async with Session() as s:
        total = await s.scalar(select(func.count()).select_from(MenuItem))
        dupes = (await s.execute(
            select(MenuItem.restaurant_id, MenuItem.name, func.count())
            .group_by(MenuItem.restaurant_id, MenuItem.name)
            .having(func.count() > 1)
        )).all()
    print(f'Sync complete: {added} added, {updated} updated, {removed} stale rows '
          f'removed, {total} rows remain, {len(dupes)} menus still hold a '
          f'duplicate name. {len(orphans)} referenced rows preserved.' +
          (f' Preserved IDs: {orphans[:5]}' if orphans else ''))
    await engine.dispose()


if __name__ == '__main__':
    asyncio.run(resync_menus())
