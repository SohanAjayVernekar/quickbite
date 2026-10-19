#!/usr/bin/env python3
"""Real 100+ order measurement. No synthetic results. Run only when deliberately requested."""
import argparse
import asyncio
import json
import math
import os
import platform
import statistics
import subprocess
import time
import uuid
from datetime import datetime,timezone
from pathlib import Path
import httpx

async def run(args):
    root=Path(__file__).resolve().parents[2]
    values={}
    if (root/'.env').exists():values=dict(x.split('=',1) for x in (root/'.env').read_text().splitlines() if '=' in x and not x.startswith('#'))
    if values.get('DEMO_MODE','success')!='success' or values.get('CRASH_CHECKPOINT','none')!='none':raise SystemExit('Load baseline requires deterministic success, with crash injection disabled.')
    async with httpx.AsyncClient(base_url=args.base,timeout=30,limits=httpx.Limits(max_connections=args.concurrency+8)) as client:
        async def token(email,password):
            r=await client.post('/api/v1/auth/login',json={'email':email,'password':password});r.raise_for_status();return {'Authorization':'Bearer '+r.json()['access_token']}
        customer=await token('customer@quickbite.test','Customer@12345');admin=await token('admin@quickbite.test','Admin@12345')
        async def get(path,headers):
            r=await client.get(path,headers=headers);r.raise_for_status();return r.json()
        restaurants=(await get('/api/v1/restaurants',customer))['items'];rest=next(x for x in restaurants if x['available'])
        menu=(await get(f"/api/v1/restaurants/{rest['id']}/menu",customer))['items'];item=next(x for x in menu if x['available'])
        payload={'restaurant_id':rest['id'],'delivery_address':'10 Benchmark Avenue, Bengaluru 560001','items':[{'menu_item_id':item['id'],'quantity':1}]}
        for _ in range(120):
            summary=await get('/api/v1/admin/summary',admin);sys=await get('/api/v1/admin/system',admin)
            if sys['broker']!='connected':raise RuntimeError('Broker metrics are unavailable; cannot measure queue backlog.')
            if not summary['pending_outbox'] and not summary['retry_jobs'] and not sum(q['messages'] for q in sys['queues'] if q['name']!='orders.dead-letter.queue'):break
            await asyncio.sleep(1)
        else:raise RuntimeError('Baseline did not become idle within 120 seconds.')
        sem=asyncio.Semaphore(args.concurrency);latencies=[];orders=[];backlog=[];stop=asyncio.Event()
        async def sample():
            while not stop.is_set():
                d=await get('/api/v1/admin/system',admin)
                if d['broker']!='connected':raise RuntimeError('Broker metrics lost during load run')
                backlog.append({'elapsed_seconds':round(time.perf_counter()-started,3),'queues':d['queues']})
                await asyncio.sleep(.5)
        async def create(_):
            async with sem:
                begin=time.perf_counter();r=await client.post('/api/v1/orders',json=payload,headers={**customer,'Idempotency-Key':str(uuid.uuid4())})
                latencies.append((time.perf_counter()-begin)*1000)
                r.raise_for_status()
                if r.status_code!=202:raise RuntimeError('Expected 202')
                orders.append(r.json()['order_id'])
        start_utc=datetime.now(timezone.utc).isoformat();started=time.perf_counter();sampler=asyncio.create_task(sample())
        try:
            await asyncio.gather(*(create(i) for i in range(args.orders)))
            accepted_seconds=time.perf_counter()-started
            unfinished=set(orders);deadline=started+args.timeout
            while unfinished:
                if time.perf_counter()>deadline:raise RuntimeError(f'{len(unfinished)} orders did not finish within timeout')
                async def poll(id):
                    async with sem:
                        d=await get('/api/v1/orders/'+id,customer)
                        if d['status'] in ['FAILED','PAYMENT_FAILED']:raise RuntimeError('Baseline order failed: '+id)
                        if d['status']=='DRIVER_ASSIGNED':unfinished.discard(id)
                await asyncio.gather(*(poll(id) for id in list(unfinished)))
                if unfinished:await asyncio.sleep(.5)
            total_seconds=time.perf_counter()-started
        finally:
            stop.set();await sampler
        sorted_ms=sorted(latencies)
        instances={}
        try:
            result=subprocess.run(['docker','compose','logs','--no-log-prefix','--since',start_utc,'payment-worker'],cwd=root,capture_output=True,text=True,check=True)
            for line in result.stdout.splitlines():
                try:d=json.loads(line)
                except ValueError:continue
                if d.get('result')=='processed':
                    instance=d.get('instance','unknown');instances[instance]=instances.get(instance,0)+1
        except (OSError,subprocess.CalledProcessError):pass
        report={'recorded_at':start_utc,'payment_workers':args.workers,'order_count':len(orders),'concurrency':args.concurrency,
          'machine':{'platform':platform.platform(),'cpu_count':os.cpu_count(),'processor':platform.processor(),
                     'memory_total_kb':next((line.split(':')[1].strip() for line in Path('/proc/meminfo').read_text().splitlines() if line.startswith('MemTotal:')),'unknown') if Path('/proc/meminfo').exists() else 'unavailable'},
          'simulation_delays_ms':{x:values.get(x+'_DELAY_MS','default') for x in ['PAYMENT','RESTAURANT','DELIVERY','NOTIFICATION']},
          'api_p50_ms':statistics.median(latencies),'api_p95_ms':sorted_ms[math.ceil(.95*len(sorted_ms))-1],
          'all_accepted_seconds':accepted_seconds,'total_processing_seconds':total_seconds,'orders_per_second':len(orders)/total_seconds,
          'max_queue_backlog':max((sum(q['messages'] for q in snap['queues'] if q['name']!='orders.dead-letter.queue') for snap in backlog),default=0),
          'queue_samples':backlog,'payment_instance_processing_counts':instances,'p95_target_ms':500}
        output=root/'docs/evidence/runs'/f'load-{args.workers}workers-{uuid.uuid4().hex[:8]}.json';output.parent.mkdir(parents=True,exist_ok=True);output.write_text(json.dumps(report,indent=2))
        print(json.dumps({k:v for k,v in report.items() if k not in ['queue_samples']},indent=2));print('Saved',output)
if __name__=='__main__':
    parser=argparse.ArgumentParser();parser.add_argument('--base',default='http://localhost:8000');parser.add_argument('--orders',type=int,default=100);parser.add_argument('--concurrency',type=int,default=10);parser.add_argument('--workers',type=int,choices=[1,3],required=True);parser.add_argument('--timeout',type=int,default=600);args=parser.parse_args()
    if args.orders<100 or args.concurrency<1:parser.error('Use at least 100 orders and positive concurrency.')
    asyncio.run(run(args))
