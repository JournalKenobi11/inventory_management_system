# Comprehensive Application QA Audit Report

## 1. Executive Summary & Overview
This QA audit represents an end-to-end evaluation of the **Garage & Inventory Management System** (Flutter + Drift/SQLite + Riverpod).
The application is architected around a clean-layered pattern with domain feature modules under `lib/features/`, repository interfaces, SQLite persistence via Drift, and Riverpod controllers.

The application was populated with dummy data to explore edge cases, large numbers, long text strings, rapid navigation, and data integrity boundaries.

---

## 2. Architecture & Layering Assessment
The project strictly establishes the following dependency direction in accordance with `AGENTS.md`:
`Screens/Widgets → Providers → Services → Repository Interfaces → SQLite Repositories → Drift/SQLite`

### Audit of Layering Compliance:
- **Repository Interface Decoupling:** Repository interfaces under `repositories/interfaces/` return plain model classes from `models/` without leaking Drift data classes.
- **Service Encapsulation:** Business logic (profit calculations, stock adjustments, date filtering, salary deductions) is concentrated in `services/`.
- **Cross-feature communication:** Features communicate through public feature export files (e.g. `features/billing/billing.dart`, `features/customers/customers.dart`).
- **Transactional integrity:** Multi-step stock deductions and purchase records utilize SQLite transactions to prevent partial writes.

---

## 3. Audited Screens & Features

| Feature | Screens & Dialogs Audited | State Providers / Services |
|---|---|---|
| **Dashboard** | `DashboardScreen`, `_SummaryCard`, `_DateControls`, `_ServiceRemindersAlert` | `dashboardProvider`, `DashboardService` |
| **Billing & Invoices** | `BillingScreen`, `InvoiceOverviewScreen`, `_SearchablePartDialog`, `_SearchableCustomerDialog` | `billingProvider`, `BillingService`, `BillingController` |
| **Parts & Inventory** | `PartListScreen`, `PartFormScreen`, `_PartCard` | `partsProvider`, `PartService` |
| **Purchases (Stock-In)** | `PurchaseEntryScreen` | `purchasesProvider`, `PurchaseService` |
| **Customers** | `CustomerListScreen`, `CustomerFormScreen`, `CustomerDetailScreen` | `customersProvider`, `CustomerService` |
| **Expenses** | `ExpensesScreen`, `ExpenseEntryScreen` | `expensesProvider`, `ExpenseService` |
| **Staff & Salaries** | `EmployeeListScreen`, `EmployeeFormScreen`, `SalaryPaymentEntryScreen`, `PendingPaymentsScreen`, `RecordAttendanceDialog`, `EmployeeAttendanceDetailScreen` | `employeesProvider`, `salaryPaymentsProvider`, `SalaryService`, `AttendanceService` |
| **Personal Finance** | `PersonalFinanceScreen`, `PersonalFinanceTransactionEntryScreen` | `personalFinanceProvider`, `PersonalFinanceService` |
| **Reports & Analytics** | `ReportsScreen`, Tab views (Sales, Expenses, Profit, Inventory, Customers) | `reportProvider`, `ReportService` |
| **Backup & Recovery** | `BackupScreen`, JSON Export/Import dialogs, SQLite file export | `backupProvider`, `BackupService` |

---

## 4. Major Identified Weaknesses & Patterns

### 1. Data Loss in Backup & Restore
- The database schema was upgraded to version 4 (adding `Attendances` table and `serviceJobs.serviceReport`, `serviceJobs.labourEntries`).
- However, `SqliteBackupRepository.exportAllTables()` and `restoreAllTables()` omitted `attendances` and the schema v4 fields!
- **Consequence:** Restoring a backup completely wiped employee attendance records and erased service reports & itemized labour charges.

### 2. Double-Deduction and Profit Formula Discrepancy
- In `ReportService.getExpenseReport()`, stock restocking purchases were added into `totalBusinessExpenses` and `totalExpenses`.
- In `ReportService.getProfitReport()`, `cashProfit` calculated: `totalRevenue - (totalExpenses + stockPurchases)`. Because `totalExpenses` already contained `stockPurchases`, stock purchases were deducted twice.
- In `DashboardService.getSummary()`, `summary.profit` was changed to `totalSales - totalExpenses` (Cash Flow) instead of `totalSales - cogs` (Gross Profit / Proper Profit), contradicting `USER_MANUAL.md` and failing unit tests.

### 3. UI RenderFlex Overflow with Large Numbers
- `_SummaryCard` in `DashboardScreen` utilized an unconstrained `Row` with `mainAxisAlignment: spaceBetween` containing an `Icon` and `Text(subtitle!)`.
- When stock purchases were large (e.g. ₹1.25 Crore in dummy data), the subtitle exceeded the grid cell width (126px on a 360px screen), overflowing by 91 pixels on the right.

### 4. Edit Bill Stock Constraints & Compiler Mismatches
- In `BillingScreen` edit mode, existing line items were given dummy `Part` models with `currentStock: item.quantity`.
- The quantity increment button checked `if (quantity > item.part.currentStock)`, preventing the user from increasing quantity even if the warehouse had ample stock.
- Constructor parameter names and provider names were mismatched (`amount` vs `charge`, `allInvoicesProvider` vs `invoicesListProvider`).

### 5. Dropdown Selection Framework Crash
- `PurchaseEntryScreen` used `Part` directly as the dropdown item value in `DropdownButtonFormField<Part>`.
- `Part.operator ==` checks all fields including `currentStock`. When stock changes or when initialized with a preselected part whose stock was modified, the value does not match any item in the dropdown list, causing a Flutter framework assertion crash.

### 6. Asymmetric Confirmation Safety & Uncaught Exceptions
- `EmployeeListScreen` guarded deletion with a confirmation dialog; `CustomerListScreen` deleted customers immediately on popup menu tap with no confirmation.
- `CustomerFormScreen` lacked a `catch` block on `_save()`, causing validation or duplicate entry errors to crash the async turn without showing feedback to the user.
- State invalidation was missing when a new bill was generated, leaving inventory stock and dashboard metrics stale across tabs.
