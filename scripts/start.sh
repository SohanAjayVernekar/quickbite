#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
python3 scripts/prepare_env.py
docker compose build
docker compose up -d --wait postgres rabbitmq
docker compose run --rm migrate
docker compose run --rm seed
docker compose run --rm seed-orders
docker compose up -d
printf 'QuickBite startup requested. Use docker compose ps for actual health.\n'
