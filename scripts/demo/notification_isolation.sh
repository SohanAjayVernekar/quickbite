#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/../.."
trap 'docker compose start notification-worker' EXIT
docker compose stop notification-worker
backend/.venv/bin/python scripts/demo/order.py --track
docker compose exec -T rabbitmq rabbitmqctl list_queues name messages_ready messages_unacknowledged consumers
docker compose start notification-worker
trap - EXIT
printf 'Notification worker restarted. Refresh the notification feed to observe draining.\n'
