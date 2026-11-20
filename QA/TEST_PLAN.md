# Comprehensive QA Test Plan

## 1. Scope & Objectives
This test plan validates data integrity, state synchronization, accounting correctness, responsive layout, and crash resilience across all 10 features of the Garage & Inventory Management System.

---

## 2. Test Execution Levels

### Level 1: Static Code Analysis & Architecture Constraints
- Run `flutter analyze` with 0 warnings, 0 errors, and 0 lints.
- Run architecture validation to ensure no illegal imports across layers or features.

### Level 2: Database Migration & Backup/Restore Integrity
- Verify fresh DB creation (schemaVersion 4) and default account seeding.
- Verify migrations from v1, v2, v3 to v4.
- Verify complete backup export of all tables (including `attendances`, `serviceJobs.serviceReport`, and `serviceJobs.labourEntries`).
- Verify roundtrip restore without record loss or foreign key violation.

### Level 3: Business Logic & Accounting Verification
- **Gross Profit Formula:** $\text{Gross Profit} = \text{Sales Revenue} - \text{COGS}$.
- **Operating Net Profit:** $\text{Operating Profit} = \text{Gross Profit} - (\text{Business Expenses} + \text{Salaries})$.
- **Net Cash Flow / Cash Profit:** $\text{Cash Profit} = \text{Revenue} - (\text{Operating Expenses} + \text{Salaries} + \text{Stock Restocking Purchases})$.
- Verify stock deductions during billing and stock additions during restocking purchases.
- Verify edit bill restores previous stock before validating and deducting new stock.

### Level 4: UI & Layout Responsiveness Matrix
Test layouts on the following viewports without RenderFlex overflow:
- Narrow Mobile: 320 x 568 (iPhone SE)
- Compact Android: 360 x 640
- Standard Modern Phone: 390 x 844
- Tablet / Desktop: 720 x 1024, 1024 x 768
- Font Scaling: 1.5x accessibility text scaler factor.
- Extreme Data: 10-digit currency values (₹1,00,00,000+), 80-character part/customer names.

### Level 5: State Synchronization & Error Handling
- Deleting items (customers, parts, employees, transactions) confirms with user and handles foreign-key blocks cleanly.
- Form submissions display feedback SnackBars on validation failure.
- Creating invoices refreshes stock in inventory and summary figures on dashboard without manual app restart.
