#!/usr/bin/env python3
"""Create a real demo order. Optional duplicate checkout prints the same acceptance ID."""
import argparse
import asyncio
import json
import os
import uuid
import httpx

async def run():
    p=argparse.ArgumentParser();p.add_argument('--base',default=os.getenv('QUICKBITE_API','http://localhost:8000'))
    p.add_argument('--idempotency',action='store_true');p.add_argument('--track',action='store_true');a=p.parse_args()
    async with httpx.AsyncClient(base_url=a.base,timeout=20) as c:
        r=await c.post('/api/v1/auth/login',json={'email':'customer@quickbite.test','password':'Customer@12345'});r.raise_for_status()
        c.headers['Authorization']='Bearer '+r.json()['access_token']
        restaurants=(await c.get('/api/v1/restaurants')).json()['items']
        restaurant=next(x for x in restaurants if x['available'])
        menu=(await c.get(f"/api/v1/restaurants/{restaurant['id']}/menu")).json()['items']
        item=next(x for x in menu if x['available'])
        payload={'restaurant_id':restaurant['id'],'delivery_address':'12 Demo Garden Road, Bengaluru 560001','items':[{'menu_item_id':item['id'],'quantity':1}]}
        key=str(uuid.uuid4());headers={'Idempotency-Key':key}
        r=await c.post('/api/v1/orders',json=payload,headers=headers);r.raise_for_status()
        print('HTTP',r.status_code,json.dumps(r.json()));order_id=r.json()['order_id']
        if a.idempotency:
            again=await c.post('/api/v1/orders',json=payload,headers=headers);again.raise_for_status()
            print('Repeated acceptance:',again.json()['order_id'],'same_id=',again.json()['order_id']==order_id)
        if a.track:
            for _ in range(120):
                current=await c.get('/api/v1/orders/'+order_id);current.raise_for_status();state=current.json()
                print(state['status'],'version',state['version'])
                if state['status'] in ['DRIVER_ASSIGNED','PAYMENT_FAILED','FAILED']:break
                await asyncio.sleep(2)
            else:raise SystemExit('Still processing after 240 seconds; inspect services.')
if __name__=='__main__':asyncio.run(run())
