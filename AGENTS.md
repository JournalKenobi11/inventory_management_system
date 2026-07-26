# AGENTS.md

This file is the single source of truth for how this codebase must be
built. Any AI tool, or human, working on this repo must follow these
rules regardless of which tool is used. If a rule here conflicts with a
convenience shortcut, this file wins.

Reference docs (read the relevant one before touching a module):
- `/docs/design_doc.md` — original product/feature spec
- `/docs/build_plan.md` — phases, schema, testing strategy
- `/docs/module_plan.md` — per-module file breakdown and method signatures
- `/docs/schema.sql` — canonical database schema, do not redesign tables ad hoc

---

## Architecture rules — do not violate

1. **Layering is one-directional:**
   `Screens/Widgets → Providers → Services → Repository Interfaces → SQLite Repositories → Drift/SQLite`
   A layer may only call the layer directly below it. Screens never import
   anything from `database/` or `repositories/sqlite/` directly.

2. **All business logic lives in `services/`.** Validation, money math,
   stock math, transaction sequencing (e.g. billing: check stock → deduct
   → snapshot price → generate invoice) — all of it belongs in a Service
   method, never in a Screen, Widget, or Provider.

3. **Repository interfaces return plain model classes from `models/`,
   never Drift-generated row classes.** The SQLite repository implementation
   converts Drift rows ↔ models internally. This is what keeps a future
   server/API repository a drop-in replacement instead of a rewrite.

4. **Every repository method returns `Future<T>`**, even though SQLite is
   effectively synchronous-fast. This keeps the interface identical when
   an API-based repository (inherently async) replaces it later.

5. **No SQL or Drift query objects outside `repositories/sqlite/`.**
   Filtering/searching needs are named interface methods
   (e.g. `getExpensesByDateRange(start, end)`), not raw queries built in a
   Service or Screen.

6. **Errors are custom exception types**, defined in `core/errors/`
   (e.g. `InsufficientStockException`, `DuplicatePartNumberException`,
   `ValidationException`) — never raw SQLite/Drift exceptions surfaced
   upward.

7. **IDs are UUID strings.** Never let SQLite autoincrement integer IDs
   leak into models, method signatures, or the UI.

8. **One feature = one folder under `features/`, with exactly one public
   export file** (e.g. `features/customers/customers.dart`). Code outside
   a feature imports only that file — never reaches into a feature's
   internal `services/`, `repositories/`, or `models/` subfolders directly.

9. **Cross-feature interaction happens only through another feature's
   Service, via its public export.** E.g. Billing calls `PartService` and
   `CustomerService` — never another feature's repository or model directly.

10. **Prices/amounts are snapshotted at transaction time.** E.g. when
    billing a service, `price_each` on `service_parts` is copied from the
    part's current `sellingPrice` at that moment and never recalculated
    later — historical invoices must never change when today's prices change.

11. **Money-affecting or stock-affecting multi-step operations run inside
    a single DB transaction.** Partial writes (e.g. stock deducted but
    invoice not created) are not acceptable under any failure path.

---

## Before writing code for a module

1. Read the relevant section of `/docs/module_plan.md` for that module's
   file list and method signatures.
2. Check `/docs/schema.sql` for the exact tables/columns involved — do not
   invent new columns or tables without updating that file first.
3. Follow the build order in `/docs/build_plan.md` — do not build Billing
   (Module 4) logic before Customers/Parts/Purchases (Modules 1–3) exist
   and are tested.

## Every change must

- Pass `flutter analyze` with zero warnings.
- Pass `flutter test` (full suite).
- Include or update unit tests for any Service method that touches money,
  stock, or invoice numbering — no exceptions, even for "small" changes.
- Not violate the layering/import rules above — this is checked
  automatically in CI (see `scripts/check_architecture.sh`), and a CI
  failure here blocks the merge regardless of what generated the code.

## What NOT to do, even if asked

- Do not "simplify" the Repository pattern by having a Screen or Provider
  call Drift/SQLite directly, even temporarily "to save time."
- Do not recompute historical invoice totals from current part prices.
- Do not add a new top-level architecture layer or restructure
  `features/` without updating this file and `/docs/module_plan.md` first.
- Do not introduce a second source of truth for these rules (e.g. a
  tool-specific rules file with different/additional instructions). If a
  tool requires its own config file, it should reference this file rather
  than duplicate or override it.
