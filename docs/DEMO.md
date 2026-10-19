# Reproducible demonstration workflows

These are provided workflows, not recorded results. They were not executed for this delivery. Use a local development stack and fictional data only. Run commands from the repository root unless stated otherwise.

## Start and use QuickBite

1. Start Docker, then run `bash scripts/start.sh`. It creates random local configuration, builds images, migrates, seeds and starts services. Existing named volumes are retained.
2. Open `http://localhost:8080`, explore the landing page and sign in as `customer@quickbite.test` / `Customer@12345`.
3. Open a restaurant, add available dishes, adjust quantities, supply a fictional complete delivery address and check out.
4. The acceptance screen represents HTTP 202 and PENDING, not completed delivery. Track the order to DRIVER_ASSIGNED, then inspect history and persisted notifications.
5. Sign out and sign in as `admin@quickbite.test` / `Admin@12345` for aggregate counts, cross-customer order filtering and read-only backlog diagnostics. Admin has no checkout.

The default simulation can advance quickly. Inspect append-only history for every committed transition; the UI does not invent intermediate states. `docker compose ps` and service logs show actual runtime status on your machine.

## Prepare optional host demo clients

Install uv if needed on the host, then run `uv sync --frozen --project backend`. The Python clients use `backend/.venv/bin/python`. This host environment is not needed to run the application through Docker. On Windows, use WSL for the shell workflows.

## Repeat a checkout safely

```bash
backend/.venv/bin/python scripts/demo/order.py --idempotency --track
```

The script submits the exact same request/key twice and prints both accepted order IDs. Inspect the database constraints and query examples in [reliability](architecture/reliability.md) for unique effects. In Flutter, a timeout retains the pending request and key for safe retry. A changed request with the same key returns 409.

## Notification isolation

```bash
bash scripts/demo/notification_isolation.sh
```

The script stops only the notification worker, places and tracks an order, displays queue counts and restarts the notification worker. Refresh the persisted notification feed to observe draining. Notification processing must not change business order status.

## Delayed retry and exhausted failure

```bash
python3 scripts/failures/configure.py payment_fail_twice
backend/.venv/bin/python scripts/demo/order.py --track
python3 scripts/failures/configure.py payment_always_fail
backend/.venv/bin/python scripts/demo/order.py --track
python3 scripts/failures/configure.py success
```

Inspect retry due times, attempts and the targeted outbox records. The default schedule is initial delivery plus 2, 10 and 30 second delayed retries. The always-failing payment scenario ends at PAYMENT_FAILED and creates quarantine/dead-letter records. The same developer script supports `payment_decline`, `restaurant_terminal`, `delivery_terminal` and `notification_fail`. Restore `success` after each demonstration. These controls are not checkout fields and are prohibited in production configuration.

## Worker crash boundaries

```bash
bash scripts/demo/crash.sh
```

This uses a durable one-time checkpoint to terminate the payment process after commit and before ACK. Compose restarts the process. The redelivery should find the processed-event record and avoid a second effect. For other boundaries, configure `--checkpoint before_commit --service payment` or `--checkpoint publish_before_mark --service outbox`. Restore the `success` scenario afterwards. Inspect logs and the database rather than assuming that process restart proves correctness.

## Broker outage and outbox recovery

```bash
bash scripts/demo/broker_outage.sh
```

The script stops RabbitMQ, requests a real order acceptance with an idempotent repeat, then restarts RabbitMQ. Follow the printed order ID in Flutter and inspect outbox/worker logs for eventual processing. Readiness can report a degraded broker while PostgreSQL acceptance remains available.

## Load and worker scaling

```bash
bash scripts/load/compare.sh
```

Use a quiet deterministic-success stack. This runs at least 100 orders for each of four runs: one payment worker and three payment workers, twice each. The harness records machine resources, real acceptance p50/p95, processing duration, throughput and queue snapshots. Reports appear under `docs/evidence/runs/` only after execution. No numbers have been prefilled.

## Platforms and deferred validation

Web deep links are served by the included Nginx fallback. See the README for Flutter development, Android emulator/device API addresses and native build commands. iOS requires macOS/Xcode. Test sources are in `backend/tests`, `frontend/test` and `frontend/integration_test`; none was run during this implementation-only delivery.
