import asyncio
from sqlalchemy import select
from app.database.session import Session,engine
from app.models.entities import User,Restaurant,MenuItem,Driver
from app.auth.security import hasher
from app.config.settings import settings

# Fictional demonstration identities. This operation is deliberately blocked in production.
ACCOUNTS=[('customer-demo','customer@quickbite.test','Aarav Mehta','CUSTOMER','Customer@12345'),
          ('customer-two','customer2@quickbite.test','Mira Rao','CUSTOMER','Customer@12345'),
          ('admin-demo','admin@quickbite.test','QuickBite Admin','ADMIN','Admin@12345')]
from app.database.catalog import CATALOG

async def seed():
    if settings().app_env=='production': raise RuntimeError('Demo seeds are forbidden in production')
    async with Session() as s,s.begin():
        for id,email,name,role,password in ACCOUNTS:
            if not await s.get(User,id):
                s.add(User(id=id,email=email,name=name,role=role,password_hash=hasher.hash(password)))
        restaurants={row.id:row for row in (await s.scalars(select(Restaurant))).all()}
        items={row.id:row for row in (await s.scalars(select(MenuItem))).all()}
        for kitchen in CATALOG:
            if kitchen.id in restaurants:
                # Refresh demo artwork while retaining all operational fields.
                restaurants[kitchen.id].image=kitchen.image
            else:
                s.add(Restaurant(id=kitchen.id,name=kitchen.name,cuisine=kitchen.cuisine,
                    description=kitchen.description,image=kitchen.image,
                    rating_tenths=kitchen.rating,eta_minutes=kitchen.eta))
        await s.flush()
        for kitchen in CATALOG:
            for index,dish in enumerate(kitchen.menu,1):
                mid=f'{kitchen.id}-{index}'
                if mid in items:
                    items[mid].image=dish.image
                else:
                    s.add(MenuItem(id=mid,restaurant_id=kitchen.id,name=dish.name,
                        description=dish.description,image=dish.image,price_minor=dish.price,
                        currency='INR',available=dish.available,vegetarian=dish.vegetarian))
        for n,name in enumerate(['Dev Sharma','Neha Patil','Kabir Sen','Anaya Shah'],1):
            id=f'driver-{n}'
            if not await s.get(Driver,id): s.add(Driver(id=id,name=name,vehicle='Simulated electric scooter'))
    print(f'Seed complete: 3 fictional accounts, {len(CATALOG)} restaurants, {sum(len(k.menu) for k in CATALOG)} dishes, 4 simulated drivers. Demo images refreshed; existing operational data preserved.')
    await engine.dispose()
if __name__=='__main__': asyncio.run(seed())
