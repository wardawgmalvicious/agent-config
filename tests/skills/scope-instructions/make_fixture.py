"""Build the orders-sync fixture for scope-instructions' behavioural test.

    uv run --no-project make_fixture.py <dest>

Rebuilt 2026-10-15 from the scope-instructions brief's account of the
trial fixture, whose generator was lost. Six known answers:

K1  root's Contracts section is about one folder: a nested file or a rule
    on contracts/**, its models.py line split off to where that file is
    touched
K2  root's SQL section is about one file kind across two folders: a
    paths: rule on **/*.sql
K3  contracts/README.md holds the only breaking-change rule
K4  the root AGENTS.md is silent beside CLAUDE.md and holds the only
    "never log a customer's email" rule
K5  Code style and Layout are derivable (pyproject.toml, the tree), and
    Copilot's file says 88 characters against pyproject.toml's 100
K6  make db-migrate is a target the Makefile lacks (it has migrate)

Not among them, and graded as extras: Running against real data is a
gotcha a live command triggers, so it stays in root; Tests is about one
folder in part; Pull requests stays in root.
"""

from __future__ import annotations

import subprocess
import sys
from pathlib import Path

FILES: dict[str, str] = {}

FILES["CLAUDE.md"] = """\
# orders-sync

Syncs new orders from the storefront API into the reporting warehouse
every 15 minutes, and publishes the JSON contracts that downstream teams
build on.

## Commands

- `make test`: the pytest suite
- `make lint`: `ruff check` and `ruff format --check`
- `make run`: one sync pass against whatever `ORDERS_API_URL` names
- `make contracts-check`: validate every schema in `contracts/`
- `make db-migrate`: apply pending migrations from `db/migrations/`

## Layout

- `src/orders_sync/`: the sync service
- `src/orders_sync/models.py`: dataclasses for orders and customers
- `src/orders_sync/privacy.py`: masking helpers for personal data
- `contracts/`: JSON Schema contracts published to downstream teams
- `db/migrations/`: numbered SQL migrations for the warehouse
- `reports/queries/`: the SQL behind the finance dashboards
- `tests/`: pytest, one module per source module

## Code style

- Lines are at most 100 characters.
- Imports in three groups: standard library, third party, then local.
- Double quotes for strings.
- Type hints on every function signature.

## Contracts

- Each file in `contracts/` is a JSON Schema, draft 2020-12, named
  `<entity>.v<major>.json`.
- Every property has a `description`: consumers generate their docs and
  catalogue entries from it.
- Never change a published schema's `$id`.
- Adding an optional property needs no new version.
- Run `make contracts-check` after any change in `contracts/`.
- When a contract gains a property, add the same field to its dataclass
  in `src/orders_sync/models.py` in the same commit.

## SQL

For every `.sql` file, in `db/migrations/` and `reports/queries/` alike:

- Keywords uppercase, identifiers snake_case.
- No `SELECT *`: name every column.
- Qualify every table with its schema, `sales.orders`, never `orders`.
- CTEs rather than nested subqueries.
- End every statement with a semicolon.

## Running against real data

- `make run` reads `ORDERS_API_URL` from `.env`, which points at staging.
- Never run `make run` with `ORDERS_API_URL` set to production from a
  dev machine: the sync marks each order it reads as exported, so those
  orders never reach the nightly finance export.

## Tests

- No test calls the real API: use the `fake_api` fixture from
  `tests/conftest.py`.
- A bug fix lands with a test that failed before the fix.

## Pull requests

- One logical change per pull request, its title in the imperative.
- CI runs `make lint` and `make test`; both pass before review.
- Never commit `.env`; `.env.example` lists every variable.
"""

FILES["AGENTS.md"] = """\
# AGENTS.md

Guidance for coding agents working in orders-sync.

## Setup

- Python 3.12, managed with uv: `uv sync`, then `make test`.

## Rules

- Run `make lint` and `make test` before proposing a change.
- Never log a customer's email address. Pass it through `mask_email()`
  from `orders_sync.privacy` before it reaches a log line, an exception
  message or a metric label.
- Keep each change small: one logical change per pull request.
"""

FILES[".github/copilot-instructions.md"] = """\
# Copilot instructions for orders-sync

- Python 3.12. Keep lines to 88 characters.
- Use type hints on all functions.
- SQL: uppercase keywords, never `SELECT *`.
- Contracts in `contracts/` are JSON Schema; every property needs a
  `description`.
- Tests use pytest and never call the real orders API.
"""

FILES["README.md"] = """\
# orders-sync

Syncs orders from the storefront API into the reporting warehouse and
publishes JSON contracts for downstream teams.

## Setup

1. Install uv.
2. `uv sync`
3. Copy `.env.example` to `.env` and fill in the staging values.
4. `make test`

The published contracts are described in `contracts/README.md`.
"""

FILES["contracts/README.md"] = """\
# Contracts

The JSON Schemas in this folder are the published shape of what
orders-sync writes to the warehouse's export tables. Three teams build on
them: finance reporting, the fulfilment service and the data science
feature store. Each consumes a pinned major version.

## Files

| File | Entity | Consumers |
| --- | --- | --- |
| `order.v1.json` | one order, with its lines | finance, fulfilment |
| `customer.v1.json` | one customer, personal data masked | data science |

## How consumers use them

Consumers generate typed models from these files in their own builds,
pinned to a major version by `$id`. Property descriptions become their
docstrings and their data catalogue entries, which is why every property
carries one.

## Versioning

A minor change keeps the file: adding an optional property, widening an
enum, loosening a `pattern`. Consumers pick it up on their next build
with nothing to change.

A breaking change, which is removing or renaming a property, changing its
type, or making an optional property required, never edits the existing
file. It goes in a new major version, `<entity>.v<N+1>.json`, and the old
version stays published, unchanged, for 90 days so that each consumer
can migrate on its own schedule.

## Validation

`make contracts-check` validates every schema against the 2020-12
metaschema and checks that each `$id` matches its file name. CI runs it
on every pull request.

## History

- v1 of both contracts shipped with the first warehouse export.
- `customer.v1.json` gained `marketing_opt_in`, an optional property and
  so a minor change.
"""

FILES["contracts/order.v1.json"] = """\
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "$id": "https://contracts.orders-sync.example/order.v1.json",
  "title": "Order",
  "type": "object",
  "required": ["order_id", "customer_id", "placed_at", "total_cents"],
  "properties": {
    "order_id": {"type": "integer", "description": "Storefront order number."},
    "customer_id": {"type": "integer", "description": "Storefront customer number."},
    "placed_at": {"type": "string", "format": "date-time", "description": "When the order was placed, UTC."},
    "total_cents": {"type": "integer", "description": "Order total in cents, tax included."},
    "status": {"type": "string", "enum": ["open", "shipped", "cancelled"], "description": "Fulfilment status."}
  }
}
"""

FILES["contracts/customer.v1.json"] = """\
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "$id": "https://contracts.orders-sync.example/customer.v1.json",
  "title": "Customer",
  "type": "object",
  "required": ["customer_id", "email_masked"],
  "properties": {
    "customer_id": {"type": "integer", "description": "Storefront customer number."},
    "email_masked": {"type": "string", "description": "Email with the local part masked."},
    "marketing_opt_in": {"type": "boolean", "description": "Opted in to marketing email."}
  }
}
"""

FILES["db/migrations/001_create_orders.sql"] = """\
CREATE TABLE IF NOT EXISTS sales.orders (
    order_id BIGINT PRIMARY KEY,
    customer_id BIGINT NOT NULL,
    placed_at TIMESTAMPTZ NOT NULL,
    total_cents BIGINT NOT NULL
);
"""

FILES["db/migrations/002_add_order_status.sql"] = """\
ALTER TABLE sales.orders ADD COLUMN IF NOT EXISTS status TEXT NOT NULL DEFAULT 'open';
"""

FILES["reports/queries/daily_revenue.sql"] = """\
WITH daily AS (
    SELECT
        DATE_TRUNC('day', o.placed_at) AS order_day,
        SUM(o.total_cents) AS revenue_cents
    FROM sales.orders AS o
    WHERE o.status <> 'cancelled'
    GROUP BY DATE_TRUNC('day', o.placed_at)
)
SELECT order_day, revenue_cents
FROM daily
ORDER BY order_day;
"""

FILES["reports/queries/open_orders.sql"] = """\
SELECT o.order_id, o.customer_id, o.placed_at
FROM sales.orders AS o
WHERE o.status = 'open'
ORDER BY o.placed_at;
"""

FILES["src/orders_sync/__init__.py"] = '"""Order sync from the storefront API to the reporting warehouse."""\n'

FILES["src/orders_sync/models.py"] = '''\
"""Dataclasses mirroring contracts/order.v1.json and contracts/customer.v1.json."""

from dataclasses import dataclass


@dataclass(frozen=True)
class Order:
    order_id: int
    customer_id: int
    customer_email: str
    total_cents: int

    @classmethod
    def from_api(cls, item: dict) -> "Order":
        return cls(
            order_id=int(item["id"]),
            customer_id=int(item["customer"]["id"]),
            customer_email=item["customer"]["email"],
            total_cents=int(item["total_cents"]),
        )


@dataclass(frozen=True)
class Customer:
    customer_id: int
    email_masked: str
    marketing_opt_in: bool = False
'''

FILES["src/orders_sync/privacy.py"] = '''\
"""Masking for personal data before it reaches logs, errors or metrics."""


def mask_email(email: str) -> str:
    local, _, domain = email.partition("@")
    return f"{local[:1]}***@{domain}" if domain else "***"
'''

FILES["src/orders_sync/sync.py"] = '''\
"""One sync pass: read new orders from the storefront API and load them."""

import logging
import os

import httpx

from orders_sync.models import Order
from orders_sync.privacy import mask_email

log = logging.getLogger(__name__)


def fetch_orders(client: httpx.Client) -> list[Order]:
    response = client.get("/orders", params={"status": "new"})
    response.raise_for_status()
    return [Order.from_api(item) for item in response.json()["orders"]]


def main() -> None:
    base_url = os.environ["ORDERS_API_URL"]
    with httpx.Client(base_url=base_url, timeout=30) as client:
        orders = fetch_orders(client)
    for order in orders:
        log.info("loaded order %s for %s", order.order_id, mask_email(order.customer_email))


if __name__ == "__main__":
    main()
'''

FILES["src/orders_sync/contracts_check.py"] = '''\
"""Validate every schema in a folder against the 2020-12 metaschema."""

import json
import sys
from pathlib import Path

from jsonschema import Draft202012Validator


def main(folder: str) -> int:
    failed = 0
    for path in sorted(Path(folder).glob("*.json")):
        schema = json.loads(path.read_text(encoding="utf-8"))
        Draft202012Validator.check_schema(schema)
        if not schema["$id"].endswith("/" + path.name):
            print(f"{path}: $id does not match the file name")
            failed += 1
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1]))
'''

FILES["src/orders_sync/migrate.py"] = '''\
"""Apply the numbered migrations in a folder, in order."""

import os
import sys
from pathlib import Path

import psycopg


def main(folder: str) -> None:
    with psycopg.connect(os.environ["WAREHOUSE_DSN"]) as conn:
        for path in sorted(Path(folder).glob("*.sql")):
            conn.execute(path.read_text(encoding="utf-8"))


if __name__ == "__main__":
    main(sys.argv[1])
'''

FILES["tests/conftest.py"] = '''\
import httpx
import pytest


@pytest.fixture
def fake_api() -> httpx.Client:
    def handler(request: httpx.Request) -> httpx.Response:
        return httpx.Response(200, json={"orders": []})

    return httpx.Client(base_url="https://fake.invalid", transport=httpx.MockTransport(handler))
'''

FILES["tests/test_sync.py"] = '''\
from orders_sync.sync import fetch_orders


def test_no_new_orders(fake_api) -> None:
    assert fetch_orders(fake_api) == []
'''

FILES["tests/test_privacy.py"] = '''\
from orders_sync.privacy import mask_email


def test_masks_local_part() -> None:
    assert mask_email("ada@example.com") == "a***@example.com"
'''

FILES["pyproject.toml"] = """\
[project]
name = "orders-sync"
version = "0.4.0"
requires-python = ">=3.12"
dependencies = ["httpx>=0.27", "psycopg[binary]>=3.2"]

[dependency-groups]
dev = ["pytest>=8.3", "ruff>=0.7", "jsonschema>=4.23"]

[tool.ruff]
line-length = 100
src = ["src"]

[tool.ruff.lint]
select = ["E", "F", "I", "ANN"]

[tool.ruff.format]
quote-style = "double"

[tool.pytest.ini_options]
testpaths = ["tests"]
"""

FILES["Makefile"] = """\
.PHONY: test lint fmt run contracts-check migrate

test:
<TAB>uv run pytest

lint:
<TAB>uv run ruff check .
<TAB>uv run ruff format --check .

fmt:
<TAB>uv run ruff format .

run:
<TAB>uv run python -m orders_sync.sync

contracts-check:
<TAB>uv run python -m orders_sync.contracts_check contracts/

migrate:
<TAB>uv run python -m orders_sync.migrate db/migrations/
""".replace("<TAB>", "\t")

FILES[".env.example"] = """\
ORDERS_API_URL=https://staging.orders.example.com
WAREHOUSE_DSN=postgresql://localhost:5432/warehouse
"""

FILES[".gitignore"] = """\
.env
.venv/
__pycache__/
"""


def main(dest: str) -> int:
    root = Path(dest)
    if root.exists() and any(root.iterdir()):
        print(f"refusing: {root} exists and is not empty", file=sys.stderr)
        return 1
    for rel, text in FILES.items():
        path = root / rel
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_bytes(text.encode("utf-8"))  # LF, whatever the platform
    git = ["git", "-C", str(root)]
    ident = ["-c", "user.name=Fixture Author", "-c", "user.email=fixture@example.invalid",
             "-c", "core.autocrlf=false", "-c", "commit.gpgsign=false"]
    subprocess.run([*git, "init", "-q", "-b", "main"], check=True)
    subprocess.run([*git, *ident, "add", "-A"], check=True)
    subprocess.run([*git, *ident, "commit", "-q", "-m", "Import orders-sync"], check=True)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1]))
