#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/../.."
python3 scripts/failures/configure.py success
for repetition in 1 2; do
  for workers in 1 3; do
    docker compose up -d --scale payment-worker="$workers"
    backend/.venv/bin/python scripts/load/run.py --workers "$workers" --orders 100
  done
done
