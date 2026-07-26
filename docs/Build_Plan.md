# Inventory Management System — Engineering Build Plan

This is your execution roadmap. Follow it in order. Each phase has a clear
deliverable and a "definition of done" — don't move to the next phase until
the current one passes its checks. This is how a solo/small team ships a
production app without it collapsing under its own complexity.

---

## 0. Before You Write Any App Code

**Set up the project skeleton first, empty but correctly shaped.**

```
lib/
  core/            # constants, error types, shared utils, DI setup
  database/        # Drift schema, DAOs, migrations
  models/          # plain data classes (business entities)
  repositories/
    interfaces/    # abstract repository contracts
    sqlite/        # SQLite implementations (V1)
    api/           # empty for now — future REST implementations
  services/        # ALL business logic lives here
  providers/       # Riverpod providers — UI state + calling services
  screens/         # one folder per module (customers, billing, inventory...)
  widgets/         # reusable, presentation-only
  utils/
  theme/
test/
  services/        # unit tests — this is where most of your tests live
  repositories/     # integration tests against a test SQLite DB
```

**Rule to tattoo on your brain, from your own design doc:**
Screens/Widgets never touch the database. Repositories never contain
business logic. All money math, stock math, and validation lives in
Services. This single rule is what will keep this app stable as it grows,
and it's what makes the future FastAPI/PostgreSQL migration a repository
swap instead of a rewrite.

**Tooling to install now:**
- Flutter (stable channel) + Dart
- Drift (SQLite ORM) + drift_dev + build_runner
- flutter_riverpod
- uuid package (for internal UUIDs per section 22.7)
- flutter_test / mocktail (for unit testing services with fake repositories)

---

## 1. Database Schema (Design This Before Any Screen)

Below is the concrete schema derived from section 13 of your design doc.
Build this in Drift exactly as SQL first (even on paper/text) so you're not
redesigning tables mid-project — that's the #1 cause of big rewrites.

```sql
-- customers
CREATE TABLE customers (
  id            TEXT PRIMARY KEY,   -- UUID
  name          TEXT NOT NULL,
  mobile        TEXT NOT NULL,
  vehicle_name  TEXT,
  created_date  TEXT NOT NULL       -- ISO8601
);
CREATE INDEX idx_customers_mobile ON customers(mobile);
CREATE INDEX idx_customers_name   ON customers(name);

-- parts (inventory)
CREATE TABLE parts (
  id             TEXT PRIMARY KEY,
  part_number    TEXT UNIQUE NOT NULL,
  part_name      TEXT NOT NULL,
  category       TEXT,
  purchase_price REAL NOT NULL,
  selling_price  REAL NOT NULL,
  current_stock  INTEGER NOT NULL DEFAULT 0,
  low_stock_threshold INTEGER NOT NULL DEFAULT 5
);

-- purchases (stock-in events — never edit current_stock directly)
CREATE TABLE purchases (
  id              TEXT PRIMARY KEY,
  part_id         TEXT NOT NULL REFERENCES parts(id),
  quantity        INTEGER NOT NULL,
  purchase_price  REAL NOT NULL,
  purchase_date   TEXT NOT NULL
);

-- services (a billing event / job for a customer)
CREATE TABLE services (
  id             TEXT PRIMARY KEY,
  customer_id    TEXT NOT NULL REFERENCES customers(id),
  problem_desc   TEXT,
  labour_charge  REAL NOT NULL DEFAULT 0,
  service_date   TEXT NOT NULL,
  invoice_id     TEXT REFERENCES invoices(id)
);

-- service_parts (parts consumed in a given service — line items)
CREATE TABLE service_parts (
  id           TEXT PRIMARY KEY,
  service_id   TEXT NOT NULL REFERENCES services(id),
  part_id      TEXT NOT NULL REFERENCES parts(id),
  quantity     INTEGER NOT NULL,
  price_each   REAL NOT NULL   -- snapshot of selling_price at time of billing
);

-- invoices
CREATE TABLE invoices (
  id             TEXT PRIMARY KEY,
  invoice_number INTEGER UNIQUE NOT NULL,  -- auto-incrementing, generated in Service layer
  service_id     TEXT NOT NULL REFERENCES services(id),
  total_amount   REAL NOT NULL,
  created_date   TEXT NOT NULL
);

-- expenses
CREATE TABLE expenses (
  id           TEXT PRIMARY KEY,
  category     TEXT NOT NULL,       -- Rent, Electricity, Internet, Fuel, Equipment, Tools, Tea & Snacks, Misc
  is_personal  INTEGER NOT NULL DEFAULT 0,  -- 0 = business, 1 = personal
  amount       REAL NOT NULL,
  note         TEXT,
  entry_date   TEXT NOT NULL        -- auto-recorded, not user-entered
);

-- employees
CREATE TABLE employees (
  id             TEXT PRIMARY KEY,
  name           TEXT NOT NULL,
  monthly_salary REAL NOT NULL
);

-- salary_payments
CREATE TABLE salary_payments (
  id            TEXT PRIMARY KEY,
  employee_id   TEXT NOT NULL REFERENCES employees(id),
  amount        REAL NOT NULL,
  payment_date  TEXT NOT NULL,
  status        TEXT NOT NULL   -- 'paid' | 'pending'
);
```

**Important design notes:**
- `current_stock` on `parts` is a derived/cached value, but it's only ever
  changed by Services (never directly by a screen) — every purchase adds to
  it, every billed service subtracts from it, inside a single transaction.
- `price_each` is snapshotted onto `service_parts` at billing time — never
  recompute historical invoices from today's `selling_price`. This is the
  single most common bug in billing systems: prices change, and old
  invoices silently "change" with them if you don't snapshot.
- IDs are UUIDs (text), per section 22.7 — this makes the future Postgres
  migration painless and avoids ID collisions if you ever go multi-device.
- Dates stored as ISO8601 text — SQLite has no native date type, and this
  keeps sorting/filtering simple and Postgres-compatible.

---

## 2. Build Order (Phases, with Definition of Done)

Do not start a phase until the previous one's DoD is checked off. Each
phase should be its own git branch, merged only when its tests pass.

### Phase 1 — Foundation
- Drift database set up with the schema above, migrations working.
- DI wiring (how Services get their Repositories) decided and working —
  even a simple manual provider setup is fine, don't over-engineer this.
- **DoD:** app boots, empty DB creates cleanly, one dummy row round-trips
  through a repository in a test.

### Phase 2 — Customers, Parts, Inventory (pure CRUD, no money math)
- Customer repository + service + screens (add/edit/delete/search).
- Parts repository + service + screens, including low-stock flag logic.
- Purchase entry increases stock (through Service, inside a transaction).
- **DoD:** you can add a customer, add a part, record a purchase, and see
  stock go up. Unit tests cover: duplicate part numbers rejected, stock
  increases match purchase quantity.

### Phase 3 — Billing (the highest-risk module — go slow here)
- Search/select customer or create new.
- Add parts with quantity (checked against current stock).
- Add labour charge.
- Generate invoice: auto invoice number, snapshot prices, deduct stock,
  update customer history — **all inside one atomic transaction.**
- **DoD:** tests exist for — billing with insufficient stock fails cleanly
  and stock is unchanged; billing with sufficient stock deducts exact
  quantities; invoice numbers never collide even with rapid entries;
  a part's price change after billing does not alter past invoices.

### Phase 4 — Expenses & Salaries
- Expense entry (business/personal split), auto date/time.
- Employee CRUD + salary payment recording with status.
- **DoD:** business vs personal expenses are queryable separately; salary
  payment history is immutable once recorded (edits create adjustments,
  not silent overwrites, if you want an audit trail — your call, but
  decide this now rather than later).

### Phase 5 — Dashboard
- Aggregates: sales, expenses, profit, services completed, inventory
  value, low stock, top-selling parts — all computed in Services from
  raw tables, never stored redundantly.
- Date range filters: this month / this year / custom.
- **DoD:** dashboard numbers are cross-checked by hand against a small
  set of manually-entered test transactions.

### Phase 6 — Reports & Analytics
- Monthly/yearly/custom range reports, same data sources as dashboard.
- Top customers, top parts, salary expense reports.
- **DoD:** every report is read-only and derived — no report writes to
  the DB. Spot-check totals against Phase 5's dashboard for consistency.

### Phase 7 — PDF / GST / Backup / Export
- PDF invoice generation, GST-ready invoice fields, backup/export,
  WhatsApp share of invoice.
- **DoD:** a generated PDF invoice matches the DB record exactly; backup
  file can be restored into a fresh install and reproduces the same data.

---

## 3. Testing Strategy (Do Not Skip This)

For a homelab-deployed real app, this is non-negotiable, not optional polish:

- **Unit test every Service method**, especially billing, stock deduction,
  and invoice numbering. Use a fake/in-memory repository implementation so
  tests run fast and don't touch a real DB.
- **Integration test the SQLite repositories** against a real (temp) SQLite
  file to catch schema/query bugs unit tests can't see.
- **Golden-path + edge-case pairs** for every money-related operation:
  e.g. "billing succeeds" AND "billing fails gracefully when stock is 0."
- Run the full test suite before every merge to your main branch. This is
  the safety net that lets you (or an AI) touch one module without
  silently breaking another.

---

## 4. Working Safely With AI Help (Given Your Setup)

Since you're doing the implementation yourself in your homelab:

- Treat this plan + the schema above as the **fixed contract**. When you
  ask any AI tool for code, give it the specific phase/module and the
  relevant table(s) — not "build the app."
- Ask for one layer at a time (e.g. "Customer repository interface + SQLite
  implementation only") rather than a whole module in one shot — easier to
  read, easier to review, easier to test in isolation.
- After generating any Service method that touches money or stock, write
  the test for it yourself (or ask for the test alongside the code) before
  moving on. This is where "vibe coded" apps quietly rot — untested
  money/stock logic that looks right but isn't.
- Keep the design doc and this plan as your source of truth across
  sessions — paste the relevant section back in each time rather than
  relying on any tool to "remember" earlier decisions.

---

## 5. Git Workflow (per section 23.17)

- `main` — always deployable.
- `develop` — integration branch.
- `feature/<phase-name>` — one branch per phase/module, merged into
  `develop` only after tests pass, then `develop` → `main` at release
  points.
- Commit messages describe *why*, not just *what* (e.g. "Snapshot part
  price on service_parts to protect historical invoices from price
  changes").

---

## 6. Definition of Done (Whole Project)

A feature — and eventually the whole app — is done only when:
1. It's implemented following the layered architecture (no shortcuts).
2. Inputs are validated in the Service layer.
3. Unit tests exist and pass for its business logic.
4. It's documented (a short comment on *why*, for anything non-obvious).
5. It doesn't couple business logic to SQLite specifically (so the future
   Postgres/FastAPI migration stays a repository swap).

---

**Start here:** Phase 1, using the schema in section 1. Don't touch
billing (Phase 3) until Phases 1–2 are fully tested — that's where the
real financial risk in this app lives.
