#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
docker compose -f compose.test.yaml up -d --wait
trap 'docker compose -f compose.test.yaml down' EXIT
export TEST_DATABASE_URL='postgresql+asyncpg://quickbite:test-only-password@localhost:55432/quickbite_test'
export TEST_AMQP_URL='amqp://quickbite:test-only-password@localhost:55672/'
export DATABASE_URL="$TEST_DATABASE_URL" AMQP_URL="$TEST_AMQP_URL" APP_ENV=test
export JWT_SECRET='test-only-signing-secret-with-more-than-32-chars' RABBITMQ_PASSWORD='test-only-password'
cd backend
uv sync --frozen
uv run alembic upgrade head
uv run pytest -q
