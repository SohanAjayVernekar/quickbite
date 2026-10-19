#!/usr/bin/env python3
from pathlib import Path
import os
import secrets
root=Path(__file__).resolve().parents[1]
target=root/'.env'
if target.exists():
    print('Existing .env preserved.');raise SystemExit(0)
db=secrets.token_hex(20);broker=secrets.token_hex(20)
text=(root/'.env.example').read_text()
text=text.replace('POSTGRES_PASSWORD=CHANGE_ME','POSTGRES_PASSWORD='+db)
text=text.replace('RABBITMQ_PASSWORD=CHANGE_ME','RABBITMQ_PASSWORD='+broker)
text=text.replace('quickbite:CHANGE_ME@postgres','quickbite:'+db+'@postgres')
text=text.replace('quickbite:CHANGE_ME@rabbitmq','quickbite:'+broker+'@rabbitmq')
text=text.replace('JWT_SECRET=CHANGE_ME_TO_AT_LEAST_32_RANDOM_CHARACTERS','JWT_SECRET='+secrets.token_hex(32))
fd=os.open(target,os.O_CREAT|os.O_EXCL|os.O_WRONLY,0o600)
with os.fdopen(fd,'w') as f:f.write(text)
print('Created .env with fresh local secrets. Values were not printed.')
