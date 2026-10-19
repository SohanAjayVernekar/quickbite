# QuickBite

QuickBite is a Flutter, FastAPI, PostgreSQL and RabbitMQ food-order processing project. It contains a public landing page, customer ordering, persistent order tracking and notifications, and admin order and catalog management. Payment, restaurant acceptance and driver assignment are simulations.

**Brighter food app update:** warm ivory backgrounds, white cards, readable dark text, terracotta orange actions and green accents. All **135 distinct recipe names** now have their own bundled food artwork. Floating elements, the cart and reduced-motion support remain. The repeatable demo seed still contains **200 restaurants, 20 cuisines and 2,400 menu entries**, with original restaurant and item IDs retained.

Search finds restaurant names, cuisines and dishes. The browser supports cuisine, vegetarian-options and rating filters; recommended, fastest, rating and name sorting; and server-side pagination. Restaurant menus offer vegetarian-only filtering and regular/sharing portions. See [UI refresh](docs/UI_REFRESH.md) for the changes. No tests, analyzers or builds were run for the 17 October 2026 contrast and recipe-image update, as requested.

The existing Flutter, FastAPI, PostgreSQL and RabbitMQ architecture, authentication, checkout and worker flow are retained. Restaurants, ratings, delivery estimates, payments and drivers are demonstration data. Full service integration still needs local Docker verification.

## Update an existing installation

Extract this ZIP separately and use the included apply script to preserve local ports and configuration:

```bash
bash /path/to/extracted/quickbite-food-delivery/APPLY-UI-UPDATE.sh /path/to/your/quickbite-food-delivery
cd /path/to/your/quickbite-food-delivery
bash scripts/start.sh
```

This copies only the UI, artwork, image mappings and related documentation. Existing files are backed up under `.ui-backups/`. It does not run tests, change port settings or delete database volumes. See [update details](docs/UI_REFRESH.md).

## Start the application

Prerequisites: Docker Engine with Docker Compose v2, Python 3.12 for the environment setup script, and enough disk space for Flutter and container images. Docker must have permission to start containers. The source ZIP does not contain credentials, installed SDKs, virtual environments or database volumes.

From this directory:

```bash
./scripts/start.sh
```

This creates an ignored `.env` with fresh random secrets if it does not exist; builds images; waits for PostgreSQL and RabbitMQ; runs Alembic, the repeatable restaurant/menu seed and the safe 200-demo-order seed; then starts the app services. It does not run the test suite or load scripts. The only dependency checks during startup are service readiness checks.

Useful individual operations:

```bash
docker compose build
docker compose up -d --wait postgres rabbitmq
docker compose run --rm migrate
docker compose run --rm seed
docker compose run --rm seed-orders
docker compose up -d
docker compose ps
```

Restart with `./scripts/restart.sh`. Stop with `./scripts/stop.sh`. Named volumes survive stopping and restarting. `docker compose down -v` deletes this project's database and broker volumes; it is not part of normal startup or restart.

## Upgrade an existing QuickBite installation

Keep your current `.env` and use this source in the same project directory so Docker Compose keeps the existing volumes. Then run:

```bash
bash scripts/start.sh
```

The startup command rebuilds the API and frontend, runs migrations, inserts missing demo restaurants and menu items, and refreshes image fields for existing seeded records. Existing prices, availability, accounts and orders are retained. A simple container restart does not rebuild the UI or expand the data. Do not delete database volumes to apply this update. No new schema migration is required.

## Default local addresses

These are configured endpoints after a successful local start, **not services already running in the build workspace**.

| Service | Address |
|---|---|
| Flutter web | http://localhost:8080 |
| FastAPI | http://localhost:8000 |
| Swagger/OpenAPI UI | http://localhost:8000/docs |
| OpenAPI JSON | http://localhost:8000/openapi.json |
| Liveness | http://localhost:8000/health/live |
| Readiness | http://localhost:8000/health/ready |
| RabbitMQ management | http://localhost:15672 |

Broker management uses `RABBITMQ_USER` and the generated `RABBITMQ_PASSWORD` from your local `.env`. PostgreSQL and AMQP ports are not published on the application Compose stack. Management binds to loopback. Workers expose no host ports and have no fixed container names.

## Fictional demonstration accounts

| Role | Email | Password |
|---|---|---|
| Customer | customer@quickbite.test | Customer@12345 |
| Second customer | customer2@quickbite.test | Customer@12345 |
| Admin | admin@quickbite.test | Admin@12345 |

Passwords are Argon2 hashes in the database. These known demo identities are not real people and the seed command refuses `APP_ENV=production`. Seeding preserves existing rows and passwords. There are 200 fictional restaurants, 2,400 menu entries across 20 cuisines, 200 fictional historical demo orders, a few intentionally unavailable menu items and four simulated drivers. New restaurants have six recipes in regular/sharing portions; the original menus keep their first four items and gain eight additional choices. The catalog seed refreshes only image fields on existing seeded restaurants and menu items. The order seed fills missing demo-order IDs up to 200 and never modifies customer accounts or real orders.

## Admin catalog management

Sign in with the Admin account and open **Catalog**. The restaurant list can add restaurants, switch each restaurant between available and unavailable, or delete it. Open a restaurant to add, delete or change the availability of dishes. Image paths are optional: known dish names use their matching bundled art, and new dish names receive a generated dish illustration. Restaurant or dish records used by historical orders cannot be deleted; switch them to unavailable to keep order history intact.

## Pinned tools and dependencies

| Component | Pin |
|---|---|
| Flutter / Dart | 3.44.0 / 3.12.0 |
| Python | 3.12.14 |
| uv | 0.12.23 |
| FastAPI | 0.135.1 |
| Pydantic / settings | 2.11.7 / 2.10.1 |
| SQLAlchemy / Alembic | 2.0.41 / 1.16.2 |
| asyncpg / aio-pika | 0.30.0 / 9.5.5 |
| PyJWT / argon2-cffi | 2.10.1 / 25.1.0 |
| PostgreSQL image | postgres:17.6-bookworm |
| RabbitMQ image | rabbitmq:4.3.6-management |
| Flutter build image | ghcr.io/cirruslabs/flutter:3.44.0 |
| Web server image | nginx:1.28.0-alpine |
| Python image | python:3.12.14-slim-bookworm |
| pytest / pytest-asyncio | 8.4.1 / 1.0.0 |

Direct Python dependencies are pinned in `backend/pyproject.toml`; the full resolved graph is in `backend/uv.lock`. Flutter direct dependencies are pinned in `frontend/pubspec.yaml`; transitive versions are in `frontend/pubspec.lock`. No container uses `latest`. Container images were configured, not pulled or built in this workspace. Patch upgrades should be deliberate and accompanied by the deferred acceptance checks.

## Configuration

Read `.env.example` for every option. `scripts/prepare_env.py` generates local secrets without printing them. Real environment values, private keys and tokens must not be committed.

- `DATABASE_URL`: async PostgreSQL URL used by the API, workers, scheduler and migration process.
- `AMQP_URL`: private broker address. Never pass it to Flutter.
- `JWT_SECRET`: random secret of at least 32 characters. JWT claims include subject, role, audience, issuer, expiry, issued time and token ID. Role is checked against the active database user.
- `CORS_ORIGINS`: comma-separated explicit web origins. Authorization, content type, idempotency and request ID headers are allowed; Location and X-Request-ID are exposed. No wildcard credentialed CORS.
- `API_BIND`, `API_PORT`, `WEB_BIND`, `WEB_PORT`: local published endpoints. Defaults bind loopback. If a port is occupied, change it in `.env` and align `WEB_API_BASE_URL` and `CORS_ORIGINS` before rebuilding.
- `PAYMENT_DELAY_MS=500`, `RESTAURANT_DELAY_MS=150`, `DELIVERY_DELAY_MS=150`, `NOTIFICATION_DELAY_MS=20`: deterministic simulation timings.
- `RETRY_DELAYS=2,10,30`: initial attempt plus three delayed retries. The configured list must contain three positive numbers.
- `PREFETCH=8`: bounded AMQP in-flight delivery count per consumer.
- `ENABLE_DEMO_FAILURES`, `DEMO_MODE`, `CRASH_CHECKPOINT`, `CRASH_SERVICE`: developer-only controls. These are rejected in production and do not exist in the checkout schema.

For a deployed service, terminate HTTPS at your chosen reverse proxy and configure a reachable HTTPS API endpoint. This localhost Compose configuration is not a public TLS deployment.

## Flutter development and platform URLs

The generated `frontend/android`, `frontend/ios` and `frontend/web` targets are present. Android and iOS are native applications, not Compose containers.

```bash
cd frontend
flutter pub get --enforce-lockfile
flutter run -d chrome --web-port 5173 --dart-define=API_BASE_URL=http://localhost:8000
flutter build web --release --no-web-resources-cdn --no-wasm-dry-run --dart-define=API_BASE_URL=http://localhost:8000
```

On Android, install the Android SDK and a compatible JDK and use an emulator/device visible to `flutter devices`. This is a prerequisite on the developer machine; the generated target already exists.

```bash
flutter run -d <android-device-id> --dart-define=API_BASE_URL=http://10.0.2.2:8000
flutter build apk --debug --dart-define=API_BASE_URL=http://10.0.2.2:8000
flutter build apk --release --dart-define=API_BASE_URL=https://your-api.example
```

Local cleartext is enabled only in the Android debug manifest. Release uses HTTPS. Release signing is not configured; provide your own signing setup before distribution.

For iOS, use **macOS with Xcode**, accepted Xcode licence, simulator runtimes, and CocoaPods if needed by the plugins. The generated iOS project and keychain entitlements are present. A debug-only plist permits local networking. The release plist does not opt out of transport security.

```bash
flutter pub get --enforce-lockfile
flutter run -d <ios-simulator-id> --dart-define=API_BASE_URL=http://localhost:8000
flutter build ios --simulator --debug --dart-define=API_BASE_URL=http://localhost:8000
flutter build ios --release --no-codesign --dart-define=API_BASE_URL=https://your-api.example
```

An actual device needs a reachable LAN or HTTPS API. Set `API_BIND=0.0.0.0` deliberately for LAN development; permit the port in the host firewall. Do not put Docker names such as `api` or `postgres` in a browser/device URL. Web tokens remain in memory and require login after refresh; mobile tokens use secure storage. Pending checkout request/key and cart drafts persist per user locally. The web draft includes the delivery address until acceptance; it is browser storage, not a mobile keychain. Passwords are never persisted.

Provider/ChangeNotifier keeps authentication, cart state and order polling separate from screens. The typed repository uses one API client. Authenticated navigation uses a desktop sidebar and mobile navigation. Web deep links use path URLs with Nginx's index fallback; after re-login the original permitted route is retained.

## API and money

See [API contract](docs/api/README.md) and the committed [OpenAPI JSON](docs/api/openapi.json). All amounts use integer minor units: `1250` means INR 12.50. The customer sends restaurant, item IDs, integer quantities and address only. Each order contains up to 20 distinct items with quantities 1–20 from one restaurant. The server snapshots current names and prices.

The assignment's restaurant/menu endpoints require authentication. `/api/v1/public/catalog` is a separate bounded public preview used by the landing page. `/api/v1/notifications`, `/api/v1/admin/system` and `/api/v1/admin/quarantine` are documented extensions for the requested UI.

## Processing and reliability

Checkout commits the order, item snapshots, initial history, customer-scoped idempotency response and outbox event in one transaction. It returns HTTP 202 without waiting for the broker or workers. PostgreSQL remains authoritative.

The allowed state machine is `PENDING → PAID → CONFIRMED → DRIVER_ASSIGNED`, with terminal `PAYMENT_FAILED` from PENDING and `FAILED` from PAID/CONFIRMED. DRIVER_ASSIGNED is completion of this simulation, not physical delivery. Failures after payment do not imply a refund.

Read [architecture](docs/architecture/README.md), [reliability](docs/architecture/reliability.md) and [events](docs/events/README.md) for locking, confirmed mandatory publication, deduplication, targeted retries and quarantine. Main notification binding is `order.#`.

Readiness requires PostgreSQL and an applied migration. A bounded broker check reports degradation but broker failure alone does not return 503: accepted orders remain durable in the outbox. Database failure returns readiness 503 and prevents successful acceptance.

## Test and demo sources

**These commands were not run for this delivery.** They are provided for later validation.

```bash
./scripts/tests.sh
cd frontend && flutter test
flutter test integration_test -d <device-id> --dart-define=API_BASE_URL=<reachable-api>
```

The backend suite uses separate test services in `compose.test.yaml`, a real PostgreSQL database named `quickbite_test`, and real RabbitMQ. It refuses other database names. It deliberately truncates only the isolated test database. Tests cover API roles and ownership, validation, authoritative totals, rollback, concurrent idempotency, repeated effects, bounded retry records, quarantine, notification isolation and multi-segment routing. Worker kills, broker outages and platform flows need the supplied demos and additional execution evidence.

Set up a host Python environment for the demo/load clients with `cd backend && uv sync --frozen`. [Demo instructions](docs/DEMO.md) cover UI flow, duplicate checkout, notification outage, retries, terminal failures, crash boundaries and broker outage. All modifications are development-only.

```bash
backend/.venv/bin/python scripts/demo/order.py --idempotency --track
python3 scripts/failures/configure.py payment_fail_twice
python3 scripts/failures/configure.py payment_always_fail
python3 scripts/failures/configure.py success
./scripts/demo/notification_isolation.sh
./scripts/demo/broker_outage.sh
./scripts/demo/crash.sh
```

## Load and scaling

No benchmark measurements exist for this delivery. The reproducible harness creates at least 100 orders, measures acceptance p50/p95, total processing time, orders/second, queue snapshots and payment process distribution. It records hardware and simulation delays. It refuses non-success baseline modes and requires an idle broker/work backlog before starting.

```bash
./scripts/load/compare.sh
```

This compares one and three payment workers twice each: four runs, at least 400 total orders. JSON reports are written to `docs/evidence/runs/` only when the harness actually runs. The p95 goal is 500 ms for the documented machine, not a universal guarantee. Downstream stages, database contention and polling can limit gains.

## Troubleshooting

- **No Docker daemon / permission denied:** this workspace cannot start containers. Use the source on a host with Docker Engine permissions; do not treat missing services as a passing startup.
- **Flutter archive ownership errors in a container:** `TAR_OPTIONS=--no-same-owner` prevents restoring unavailable archived owner IDs.
- **Flutter environment detection:** `CI=true FLUTTER_SUPPRESS_ANALYTICS=true` skips cloud-instance probing and analytics. No SDK source changes are required.
- **Port conflict:** change published port variables and rebuild the web image for a changed API URL. Do not terminate an unrelated service.
- **Blank/offline catalogue:** check the browser-reachable API URL, CORS origin, successful migration and seeding.
- **401 after refresh:** web tokens are intentionally memory-only; sign in again. The saved checkout remains attached to the same customer.
- **PENDING order:** inspect `docker compose ps`, the admin system page and `docker compose logs outbox-dispatcher payment-worker`. A broker outage can leave valid orders waiting.
- **Stale notifications:** refresh after the notification worker reconnects. Business processing does not depend on notification success.
- **Unhealthy worker:** inspect its logs, database connectivity and broker credentials. Workers reconnect with backoff; they do not run migrations.
- **Changing broker/database passwords on existing volumes:** changing `.env` alone does not update accounts already stored in volumes. Update the account deliberately or use a separate fresh demo project. Normal restart preserves data.

## Important paths

- `backend/app/`: API, configuration, authentication, models, domain services and messaging.
- `backend/workers/`: independently runnable payment, restaurant, delivery and notification entrypoints.
- `backend/migrations/`: frozen initial schema, constraints and database guards.
- `frontend/lib/`: shared core and feature modules.
- `docs/architecture/`, `docs/api/`, `docs/events/`: system contracts and design.
- `docs/evidence/`: explicit implementation/build status, with no invented results.
- `docs/specification/`: the supplied assignment.
- `backend/tests/`, `frontend/test/`, `frontend/integration_test/`: unexecuted test sources.
- `scripts/demo/`, `scripts/failures/`, `scripts/load/`: reproducible demonstration and measurement tools.

## Limitations

No real payment gateway, live GPS, physical delivery, tax engine, inventory reservation, refunds, external notifications, registration or password reset is implemented. Restaurant and dish images are representative bundled photographs and generated illustrations; identical named recipes across kitchens and regular/sharing portions share their recipe image; different recipes use different images. Images do not establish exact ingredients or portions. See [image credits](docs/FOOD_IMAGE_CREDITS.md). Ratings and ETA display fields are fictional metadata. There is one persistent local broker node, not a high-availability cluster. Database and broker disk loss are outside the restart guarantee. No public deployment, real TLS termination, Apple signing, Android release signing, mobile execution evidence or measured performance result is included.
