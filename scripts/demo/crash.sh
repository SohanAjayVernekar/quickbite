#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/../.."
python3 scripts/failures/configure.py success --checkpoint after_commit_before_ack --service payment
trap 'python3 scripts/failures/configure.py success' EXIT
backend/.venv/bin/python scripts/demo/order.py --track
printf 'Inspect payment worker logs and uniqueness queries in docs/architecture/reliability.md.\n'
