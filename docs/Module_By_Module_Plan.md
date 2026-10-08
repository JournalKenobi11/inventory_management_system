# Module-by-Module Development & Assembly Plan

This extends the Build Plan with exact per-module breakdowns: what files to
create, what each layer does, method signatures, and how modules plug into
each other. Follow the module order — each one lists what it depends on.

Layer legend used throughout:
`Model → Repository Interface → SQLite Repository → Service → Provider → Screen`

---

## Module 0: Core / Foundation
**Depends on:** nothing. Build first.

**Files:**
- `core/errors/app_exceptions.dart` — `InsufficientStockException`,
  `DuplicatePartNumberException`, `NotFoundException`, `ValidationException`.
- `core/utils/id_generator.dart` — UUID generation wrapper (one place, so
  it's swappable later).
- `core/utils/date_utils.dart` — ISO8601 parse/format helpers.
- `database/app_database.dart` — Drift database class, all tables from the
  schema, migration strategy (`schemaVersion`, `onUpgrade`).
- `core/di/providers.dart` — the single place where repository
  implementations are bound to their interfaces (this is the "one switch
  point" for the future backend swap).

**Assembly output:** an app that boots, opens/creates the SQLite file, and
has zero screens. Verify with one throwaway test: insert a row into any
table, read it back.

---

## Module 1: Customers
**Depends on:** Module 0.

**Files:**
- `models/customer.dart` — plain class: `id, name, mobile, vehicleName, createdDate`. Include `toJson`/`fromJson`.
- `repositories/interfaces/customer_repository.dart`:
  ```dart
  abstract class CustomerRepository {
    Future<Customer> create(Customer customer);
    Future<Customer?> getById(String id);
    Future<List<Customer>> search(String query);
    Future<List<Customer>> getAll();
    Future<void> update(Customer customer);
    Future<void> delete(String id);
  }
  ```
- `repositories/sqlite/sqlite_customer_repository.dart` — implements the above using Drift, converts Drift rows ↔ `Customer`.
- `services/customer_service.dart` — validation (mobile format, non-empty name), calls repository. This is where you'd add "prevent duplicate mobile numbers" if you want that rule.
- `providers/customer_provider.dart` — Riverpod provider exposing customer list/search state to the UI.
- `screens/customers/` — list screen, add/edit form, detail view (shows service history — but that's populated once Module 5 exists).

**Assembly output:** standalone working feature — add, search, edit, delete a customer. No dependency on inventory/billing yet, so this is a safe first vertical slice to prove the whole layering works end-to-end.

---

## Module 2: Parts / Inventory
**Depends on:** Module 0. (Independent of Module 1 — can be built in parallel.)

**Files:**
- `models/part.dart` — `id, partNumber, partName, category, purchasePrice, sellingPrice, currentStock, lowStockThreshold`.
- `repositories/interfaces/part_repository.dart`:
  ```dart
  abstract class PartRepository {
    Future<Part> create(Part part);
    Future<Part?> getById(String id);
    Future<Part?> getByPartNumber(String partNumber);
    Future<List<Part>> getAll();
    Future<List<Part>> getLowStock();
    Future<void> update(Part part);
    Future<void> adjustStock(String partId, int delta); // used only by Services
  }
  ```
- `repositories/sqlite/sqlite_part_repository.dart`.
- `services/part_service.dart` — enforces unique `partNumber` (throws `DuplicatePartNumberException`), validates prices are non-negative.
- `providers/part_provider.dart`.
- `screens/inventory/` — parts list (with low-stock badge), add/edit part form.

**Assembly output:** standalone — add parts, see stock levels, get flagged when below threshold. Still no billing dependency.

---

## Module 3: Purchases (stock-in)
**Depends on:** Module 2.

**Files:**
- `models/purchase.dart` — `id, partId, quantity, purchasePrice, purchaseDate`.
- `repositories/interfaces/purchase_repository.dart` — `create`, `getByPartId`, `getAll`.
- `repositories/sqlite/sqlite_purchase_repository.dart`.
- `services/purchase_service.dart`:
  ```dart
  Future<void> recordPurchase(String partId, int quantity, double price) async {
    // 1. validate quantity > 0
    // 2. insert purchase record
    // 3. call partRepository.adjustStock(partId, +quantity)
    // steps 2-3 wrapped in a single DB transaction
  }
  ```
- `providers/purchase_provider.dart`.
- `screens/inventory/purchase_entry_screen.dart`.

**Assembly output:** stock now increases through a real, auditable trail (every stock change traces back to a purchase or a service — never a manual edit). This is the pattern Module 4 (billing) will mirror for stock decreases.

---

## Module 4: Services & Billing (highest risk — build carefully, test heavily)
**Depends on:** Modules 1, 2, 3.

**Files:**
- `models/service.dart`, `models/service_part.dart`, `models/invoice.dart`.
- `repositories/interfaces/service_repository.dart`, `service_part_repository.dart`, `invoice_repository.dart`.
- `repositories/sqlite/...` implementations for each.
- `services/billing_service.dart` — the core of the whole app:
  ```dart
  Future<Invoice> billService({
    required String customerId,
    required String problemDesc,
    required double labourCharge,
    required List<ServicePartInput> partsUsed, // {partId, quantity}
  }) async {
    // Inside ONE DB transaction:
    // 1. For each partsUsed: check currentStock >= quantity
    //    -> if any fails, throw InsufficientStockException, nothing written
    // 2. Create the Service record
    // 3. For each part: create ServicePart row with price snapshot
    //    (price_each = part.sellingPrice AT THIS MOMENT)
    // 4. Deduct stock via partRepository.adjustStock(partId, -quantity)
    // 5. Compute total = sum(partPrices) + labourCharge
    // 6. Generate next invoice number (see below), create Invoice
    // 7. Link invoice back to service, return Invoice
  }
  ```
- **Invoice numbering:** don't use SQLite autoincrement for the *visible*
  invoice number if you might ever run multiple devices later — instead,
  keep a `counters` table (`name TEXT, value INTEGER`) and increment it
  inside the same transaction. This avoids gaps/collisions and is
  server-migration-friendly (server can own the counter later).
- `providers/billing_provider.dart`.
- `screens/billing/` — customer select/create, part picker (shows live
  stock), labour entry, review + confirm, invoice result screen.

**Mandatory tests before moving on:**
1. Billing with enough stock → stock deducted by exact amounts, invoice total correct.
2. Billing with insufficient stock on any one part → entire operation rejected, stock unchanged, no invoice created.
3. Two billing operations run back-to-back → invoice numbers are sequential, no duplicates.
4. Change a part's `sellingPrice` after billing → old invoice's `price_each` values are unaffected.

**Assembly output:** the app's financial core works end-to-end and is proven correct by tests, not just "looks right in the UI."

---

## Module 5: Expenses
**Depends on:** Module 0 only.

**Files:**
- `models/expense.dart` — `id, category, isPersonal, amount, note, entryDate`.
- `repositories/interfaces/expense_repository.dart` — `create`, `getAll`, `getByDateRange`, `getByCategory`.
- `repositories/sqlite/sqlite_expense_repository.dart`.
- `services/expense_service.dart` — validates amount > 0, sets `entryDate` automatically (never user-entered, per your spec).
- `providers/expense_provider.dart`.
- `screens/expenses/` — entry form (category dropdown + personal/business toggle), list view.

**Assembly output:** standalone, no dependency on billing/inventory.

---

## Module 6: Employees & Salaries
**Depends on:** Module 0 only.

**Files:**
- `models/employee.dart`, `models/salary_payment.dart`.
- `repositories/interfaces/employee_repository.dart`, `salary_payment_repository.dart`.
- `services/salary_service.dart` — record payment, mark pending/paid, compute "total owed this month" per employee.
- `providers/salary_provider.dart`.
- `screens/employees/` — employee list, salary payment entry, pending-payments view.

**Assembly output:** standalone.

---

## Module 7: Dashboard
**Depends on:** Modules 1–6 all existing (it reads from all of them).

**Files:**
- `services/dashboard_service.dart` — pure aggregation, no new data written:
  ```dart
  Future<DashboardSummary> getSummary(DateRange range) async {
    // pulls from invoice, expense, salary, part repositories
    // computes: totalSales, totalExpenses, profit, servicesCompleted,
    // inventoryValue, lowStockParts, topSellingParts
  }
  ```
- `models/dashboard_summary.dart` — plain data holder for the above.
- `providers/dashboard_provider.dart`.
- `screens/dashboard/` — summary cards, date range picker, low-stock alert list.

**Assembly output:** first screen that proves all modules integrate — if numbers here don't match manual arithmetic on your test data, something upstream (usually billing) has a bug. Treat mismatches as high priority.

---

## Module 8: Reports & Analytics
**Depends on:** same as Module 7 — reuses `dashboard_service` logic patterns but with different groupings/exports.

**Files:**
- `services/report_service.dart` — monthly/yearly/custom aggregation, top customers, top parts, salary summaries. All read-only.
- `screens/reports/` — report selection, charts (consider `fl_chart` package), export trigger (hands off to Module 9).

**Assembly output:** cross-check every report total against Module 7's dashboard for the same date range — they must always agree, since they're reading the same source tables.

---

## Module 9: PDF, GST fields, Backup/Export, WhatsApp Share
**Depends on:** Module 4 (invoices) for PDF, and all modules for backup.

**Files:**
- `services/pdf_service.dart` — builds an invoice PDF from an `Invoice` + its `ServiceParts` (use the `pdf` package). Include GST fields as static template sections if you're GST-registered.
- `services/backup_service.dart` — exports the whole SQLite file (or a JSON dump of all tables) to a file; a restore function that validates and re-imports it into a fresh DB.
- `services/share_service.dart` — wraps `share_plus` to send the generated PDF via WhatsApp/other apps.
- `screens/settings/backup_screen.dart`.

**Assembly output:** a generated PDF's numbers must match the DB record exactly (write a test that renders and re-parses key fields if you want strong confidence, or manually verify against 5-10 real invoices).

---

## Module 10: Personal Finance
**Depends on:** Module 0 only. Independent manual ledger for the owner's personal money.

**Files:**
- `models/personal_finance_account.dart` — `id, name, openingBalance, createdDate`.
- `models/personal_finance_transaction.dart` — `id, accountId, type ('credit'|'debit'), amount, category, payee, note, transactionDate`.
- `models/personal_finance_categories.dart` — predefined credit and debit category lists.
- `models/personal_finance_monthly_summary.dart` — `openingBalance, totalCredits, totalDebits, netChange, currentBalance`.
- `repositories/interfaces/personal_finance_account_repository.dart` — `create, getById, getDefaultAccount, update`.
- `repositories/interfaces/personal_finance_transaction_repository.dart` — `create, getById, getAll, getByDateRange, getByType, getByCategory, getForAccount, getTotalCredits, getTotalDebits`.
- `repositories/sqlite/sqlite_personal_finance_account_repository.dart`.
- `repositories/sqlite/sqlite_personal_finance_transaction_repository.dart`.
- `services/personal_finance_service.dart` — business logic, positive-only amounts, credit/debit calculation (`openingBalance + credits - debits`), monthly summaries.
- `providers/personal_finance_provider.dart` — Riverpod state management.
- `screens/personal_finance_screen.dart` — running balance, monthly summary, transactions list (newest first).
- `screens/personal_finance_transaction_entry_screen.dart` — entry form for credits and debits.

---

## Assembly Sequence (Dependency Order)

```
Module 0 (Core/DB)
   │
   ├── Module 1 (Customers)  ──┐
   ├── Module 2 (Parts)         │
   │      └── Module 3 (Purchases)
   │                            │
   └────────────┬───────────────┘
                 ▼
        Module 4 (Billing)  ← highest risk, most tests
                 │
   ├── Module 5 (Expenses)          [independent, any time after Module 0]
   ├── Module 6 (Salaries)          [independent, any time after Module 0]
   ├── Module 10 (Personal Finance) [independent, any time after Module 0]
   │
   ▼ (needs 1-6 to have real data to aggregate)
   Module 7 (Dashboard)
                 │
   Module 8 (Reports)
                 │
   Module 9 (PDF/Backup/Share)
```

**Practical note:** Modules 1, 2, 5, and 6 have no dependency on each other
— you can genuinely build/test them in any order or even "in parallel" if
you're working with an AI tool across sessions, as long as each one is
finished and tested before Module 4 needs it.

---

## How to Use This With AI Assistance

For each module, when you ask an AI (me or otherwise) to write code:
1. Paste the exact module section above as the spec.
2. Ask for one file at a time, in this order: model → interface → SQLite
   implementation → service → provider → screen.
3. After the service layer is generated, ask for its unit tests in the
   same message — don't let a Service exist untested even briefly.
4. Run it on your server, confirm the module's "Assembly output" behavior
   before starting the next module.

This keeps every module a small, reviewable, testable unit — which is what
keeps a big app stable instead of becoming unmanageable.
