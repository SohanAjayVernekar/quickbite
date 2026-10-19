#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/../.."
trap 'docker compose start rabbitmq' EXIT
docker compose stop rabbitmq
backend/.venv/bin/python scripts/demo/order.py --idempotency
docker compose start rabbitmq
trap - EXIT
printf 'Broker restarted. Inspect the order in Flutter and outbox logs.\n'
