#!/usr/bin/env python3
"""Development-only fault configuration. Never exposes failure controls in checkout."""
import argparse
from pathlib import Path
import subprocess
p=argparse.ArgumentParser()
p.add_argument('mode',choices=['success','payment_fail_twice','payment_always_fail','payment_decline','restaurant_terminal','delivery_terminal','notification_fail'])
p.add_argument('--checkpoint',default='none',choices=['none','before_commit','after_commit_before_ack','publish_before_mark'])
p.add_argument('--service',default='payment',choices=['payment','restaurant','delivery','notification','outbox'])
a=p.parse_args();root=Path(__file__).resolve().parents[2];env=root/'.env'
if not env.exists():raise SystemExit('Start the stack once before configuring demonstrations.')
lines=env.read_text().splitlines();values=dict(x.split('=',1) for x in lines if '=' in x and not x.startswith('#'))
if values.get('APP_ENV') not in ['development','test']:raise SystemExit('Demo controls are forbidden outside development/test.')
updates={'DEMO_MODE':a.mode,'ENABLE_DEMO_FAILURES':'false' if a.mode=='success' and a.checkpoint=='none' else 'true','CRASH_CHECKPOINT':a.checkpoint,'CRASH_SERVICE':a.service}
env.write_text('\n'.join(k+'='+updates.get(k,v) if '=' in line and not line.startswith('#') else line for line in lines for k,v in [line.split('=',1) if '=' in line else ('','')])+'\n')
subprocess.run(['docker','compose','up','-d','--force-recreate','payment-worker','restaurant-worker','delivery-worker','notification-worker','outbox-dispatcher'],cwd=root,check=True)
print('Development scenario configured:',a.mode,a.checkpoint,a.service)
