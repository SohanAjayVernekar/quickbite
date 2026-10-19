# REST contract

Base prefix: `/api/v1`. Full generated schemas, field types and request bodies are in [openapi.json](openapi.json). Live Swagger UI is `/docs` once the API starts.

| Method | Path | Access | Result |
|---|---|---|---|
| POST | /auth/login | Public | Bearer token, expiry, role and user |
| GET | /me | Signed in | Current database user summary |
| GET | /public/catalog | Public | Bounded landing preview |
| GET | /restaurants | Signed in | Paginated restaurants; q matches names, cuisines and dishes. Optional cuisine, vegetarian, min_rating (0–50) and sort (recommended/rating/fastest/name). |
| GET | /restaurants/{id}/menu | Signed in | Paginated authoritative menu and restaurant; optional vegetarian=true. |
| POST | /orders | CUSTOMER | 202 acceptance and Location |
| GET | /orders | CUSTOMER | Own paginated orders, optional status |
| GET | /orders/{id} | Owner or ADMIN | State, items, address, timeline, driver, failure |
| GET | /orders/{id}/history | Owner or ADMIN | History ordered by version |
| GET | /orders/{id}/notifications | Owner or ADMIN | Notifications ordered by order version |
| GET | /notifications | CUSTOMER | Own notification feed, newest first |
| GET | /admin/orders | ADMIN | Cross-customer list with optional status |
| GET | /admin/summary | ADMIN | Status counts, outbox age, retry and quarantine counts |
| GET | /admin/system | ADMIN | Broker queue depths, unacknowledged messages and consumers |
| GET | /admin/quarantine | ADMIN | Paginated safe quarantine metadata |

Health endpoints sit outside the prefix: GET `/health/live` and GET `/health/ready`.

List pagination uses `page >= 1`, `1 <= page_size <= 100`, and `{items,page,page_size,total}`. The public preview is deliberately bounded, not a paginated user history. Timestamps use timezone-aware UTC ISO-8601. Money uses integer minor units and currency INR.

Checkout body:

```json
{
  "restaurant_id": "saffron",
  "delivery_address": "12 Demo Garden Road, Bengaluru 560001",
  "items": [{"menu_item_id":"saffron-1","quantity":2}]
}
```

Set a client-generated UUID in `Idempotency-Key`. Authenticate with `Authorization: Bearer ...`. Customer ID, price, total, failure mode and other extra fields are rejected. The address is normalized whitespace with 10–500 characters and alphabetic content. There must be 1–20 distinct items, quantities must be strict integers 1–20, items must be available and belong to the selected available restaurant. Checkout snapshots the current item names and prices.

Acceptance returns order_id, PENDING, INR, total_amount_minor, version 1 and a message. Its HTTP status is 202. The Location points at `/api/v1/orders/{order_id}`. Fetch the order to see current state. Repeating the same customer/key/payload returns the same acceptance. Changed payload is 409.

Errors use:

```json
{"code":"INVALID_INPUT","message":"Please check the supplied information.","details":{"issues":[]},"request_id":"..."}
```

401 means absent, expired, invalid or inactive-user authentication; 403 means a disallowed role; 404 also hides other customers' orders; 409 means conflicting key reuse; 422 means invalid input. Unexpected service failures return 503. Validation details never echo passwords or the rejected input. Each response has an X-Request-ID, accepting a supplied UUID or generating one.

To regenerate the contract from the configured backend environment:

```bash
cd backend
PYTHONPATH=. uv run python ../scripts/export_openapi.py
```

The exporter constructs OpenAPI without contacting PostgreSQL. It still requires configuration; load the root `.env` into the process or supply the environment variables. Compose alternative: `docker compose exec -T api python -c 'import json; from app.main import app; print(json.dumps(app.openapi(),indent=2))' > docs/api/openapi.json`.

The public catalog returns featured restaurants and dishes plus `total_restaurants` and `cuisines` from the database. The full authenticated catalog remains paginated. `vegetarian=true` on restaurants means at least one available vegetarian dish, not a vegetarian-only kitchen. Sample ETA values are not live delivery predictions.
