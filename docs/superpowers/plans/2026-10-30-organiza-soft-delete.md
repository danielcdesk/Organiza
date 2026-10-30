# Organiza Soft Delete Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add row audit timestamps and reversible soft deletion to schema 19 while keeping deleted records out of normal app reads.

**Architecture:** Add `updated_at` and nullable `deleted_at` to the ten entities named by the V3 contract. SQLite triggers maintain audit timestamps across every insert/update path; migration initializes existing rows from `created_at`. Keep direct SQL reads in `AppDatabase` and add active-row predicates there; expose an allow-listed soft-delete/restore API through repository/store. Existing delete confirmations remain, then a short snackbar offers undo.

**Tech Stack:** Flutter/Dart, sqlite3, SQLite migrations and triggers, Flutter `SnackBar`.

**Spec:** `docs/product/ORGANIZA_MEGA_PROMPT_V3.md`, Phase 2.3.

## Design

### Intent

Retain row history and make accidental deletion recoverable, preparing records for a later synchronization proposal without adding any networking. Existing users keep all data through an additive schema migration.

### Goals

- Schema 19 adds `updated_at TEXT NOT NULL` and `deleted_at TEXT NULL` to `transactions`, `accounts`, `credit_cards`, `card_purchases`, `investments`, `budgets`, `subscriptions`, `financial_goals`, `shopping_items`, and `tasks`.
- Existing data receives `updated_at = created_at`; inserts and updates keep it populated thereafter.
- Every ordinary read of those entities excludes rows with `deleted_at IS NOT NULL`.
- Existing delete actions mark rows deleted and offer a brief undo action.
- Backup/snapshot and migration reads retain deleted rows so restore does not erase audit history.

### Non-goals

- Permanent purge and retention policy; the specification makes purge optional, so defer it.
- Change business dates, balances, category calculations, account/card deletion constraints, or existing financial decisions.
- Add audit columns to unrelated tables or enable synchronization/network access.
- Expose deleted rows in normal UI or add a deleted-items browser.

### Constraints

- Follow the existing sqlite3 migration and repository patterns; SQLite remains the backend.
- Migration is safe from v1 and v18, idempotent, transactional, and preserves balances and row counts.
- Multi-row deletion/undo effects use `AppDatabase.transaction`.
- Keep money as integer cents and all UI strings in pt-BR.

### Approaches

1. **Filter in Dart after loading every row.** Rejected because tombstones still cross the database boundary and SQL aggregations or joins can leak them.
2. **Create active-only views for each table.** This centralizes reads but introduces parallel schema objects and complicates existing write queries and joins.
3. **Recommended: active predicates in the existing `AppDatabase` read SQL.** This fits the current architecture, keeps filtering close to SQL, and can be audited with a table-by-table read test. SQLite triggers maintain `updated_at` so no write path can silently omit the audit timestamp.

The selected approach follows the existing app structure. `deleted_at` is set as UTC ISO-8601 by the store's injected clock; the SQLite update trigger writes `updated_at` as UTC ISO-8601. The salary-recurring transaction delete remains atomic with schedule cancellation; undo captures and restores the canceled schedule during the snackbar window.

## Global Constraints

- Local-first: no network, telemetry, remote login, or synchronization.
- Money remains integer cents; business dates remain independent of device time zone.
- Every write that changes multiple rows uses `AppDatabase.transaction`.
- Never log financial data or backup contents.
- Schema changes increment `_schemaVersion`, migrate from v1 and the previous version, and update `docs/technical_dossier.md`.
- SQL stays out of widgets; financial rules stay out of widgets.
- User-facing text is pt-BR; preserve light/dark themes and small-screen layout.

## Review Focus

1. **Migration on populated v1 and v18 databases:** row counts, balances, and original timestamps survive; covered by migration tests.
2. **Deleted parent rows with existing foreign-key children:** logical deletion preserves referential integrity and hides the parent from normal reads; covered by account/transaction relationship tests.
3. **Deleted transactions and card purchases affecting derived totals:** only active rows affect balances, category reports, invoice totals, and projections; covered by store/report/card tests.
4. **Repeated delete or undo after another edit:** delete is idempotent, restore only restores a tombstone, and a record cannot be edited while deleted; covered by repository/store tests.
5. **Backup/restore with tombstones and recurring salary deletion:** backups retain hidden rows and undo restores both transaction and canceled schedule; covered by snapshot and widget tests.

---

### Task 1: Prove schema 19 migration behavior

**Files:**
- Modify: `test/unit/data/database_migration_test.dart`
- Modify: `test/unit/data/category_migration_test.dart` or the existing versioned migration fixture test

**Interfaces:** Existing migration fixture helpers for opening v1 and v18 stores.

- [x] **Step 1: Add failing v18 migration tests** that assert all ten tables gain both columns, `updated_at` is backfilled from each row's `created_at`, `deleted_at` is null, counts and account balances are unchanged, and foreign keys remain valid.
- [x] **Step 2: Run only the new v18 test** and confirm it fails because schema 19 columns are absent (`Expected 19, got 18`).
- [x] **Step 3: Add a failing v1-to-current assertion** proving the full sequential migration reaches 19 and preserves the seed account/transaction values.
- [x] **Step 4: Run the focused v1 test** and confirm the expected schema-version failure (`Expected 19, got 18`).

### Task 2: Implement schema 19 and timestamp triggers

**Files:**
- Modify: `lib/database/app_database.dart`
- Modify: `test/unit/data/database_migration_test.dart`
- Modify: `docs/technical_dossier.md`

**Interfaces:** `AppDatabase.currentSchemaVersion` becomes 19; add a private migration helper for the ten named tables.

- [x] **Step 1: Bump schema version** to 19 and add the v18→v19 migration in the guarded migration sequence.
- [x] **Step 2: Add the migration** to add both fields to every named table, backfill `updated_at` from `created_at`, and create `IF NOT EXISTS` triggers that initialize new rows from `created_at` and advance `updated_at` on updates. Keep migration safe to retry and execute inside the existing transaction.
- [x] **Step 3: Update integrity validation** to allow only the exact ten known audit triggers at schema 19, continue rejecting views and unknown triggers, and have `_emptyAtVersion(19)` generate the same allowed trigger set.
- [x] **Step 4: Test trigger behavior and schema validation**: new row has a nonempty audit timestamp, modifying a seeded row advances it, logical delete preserves/sets the expected fields, reopening schema 19 does not alter counts or create duplicate triggers, and an unknown trigger still fails validation.
- [x] **Step 5: Run migration tests from v1 and v18** and verify schema 19, exact row counts/balances, integrity check, and foreign-key check.
- [x] **Step 6: Update the technical dossier** with schema 19 tables, trigger behavior, and backup retention semantics.
- [ ] **Step 7: Commit** `Adicione auditoria e tombstones no schema 19`.

### Task 3: Filter normal reads and retain tombstones in backups

**Files:**
- Modify: `lib/database/app_database.dart`
- Modify: `test/unit/data/database_migration_test.dart`
- Modify or create: `test/unit/data/soft_delete_repository_test.dart`

**Interfaces:** Existing `loadAccounts`, `loadTransactions`, `loadTasks`, `loadShoppingItems`, `loadCreditCards`, `loadCardPurchases`, `loadInvestments`, `loadBudgets`, `loadSubscriptions`, and `loadFinancialGoals` remain the normal active-only reads.

- [ ] **Step 1: Add failing repository tests** that seed one active and one deleted row in each of the ten tables and assert normal loaders return only active rows, including joins and card installment reads.
- [ ] **Step 2: Verify backup test failure first**: snapshot/restore must preserve both active and deleted rows and the original `deleted_at` values.
- [ ] **Step 3: Add `deleted_at IS NULL` to every ordinary read and single-row lookup for the ten tables.** Keep migration, integrity, backup snapshot, and restore enumeration intentionally unfiltered.
- [ ] **Step 4: Run focused repository and snapshot tests** and prove active reads hide tombstones while snapshots retain them.
- [ ] **Step 5: Commit** `Filtre registros excluídos das leituras normais`.

### Task 4: Add soft-delete and restore use cases

**Files:**
- Create or modify: `lib/domain/soft_delete_entity.dart` (a typed allow-list, no caller-supplied SQL table names)
- Modify: `lib/database/app_database.dart`
- Modify: `lib/data/local_repository.dart`
- Modify: `lib/application/organiza_store.dart`
- Modify or create: `test/unit/data/soft_delete_repository_test.dart`, `test/unit/application/store_actions_test.dart`

**Interfaces:** `AppDatabase.softDelete(entity, id, deletedAtUtc)` and `AppDatabase.restore(entity, id)` return whether a row changed; `OrganizaStore` exposes guarded delete/restore actions for the currently deletable entities. All SQL identifiers come from a fixed enum-to-table map.

- [ ] **Step 1: Add failing tests** for one-time delete, repeated delete, restore, repeated restore, missing IDs, and rejecting edits to deleted rows.
- [ ] **Step 2: Implement transactional soft-delete/restore primitives** that set or clear `deleted_at`, use the injected clock in UTC for deletion time, let the timestamp trigger update `updated_at`, and never physically delete any of the ten entities.
- [ ] **Step 3: Convert existing store delete actions** (transaction, account, budget, subscription, goal, investment, task, shopping item) to the soft-delete primitive while preserving their current validation and financial-system protections.
- [ ] **Step 4: Preserve salary-series semantics**: when deleting a generated salary occurrence, cancel its schedule as today; return the schedule snapshot to the UI action so undo restores the transaction and schedule together in one transaction.
- [ ] **Step 5: Run focused store tests** for balances/report totals after delete, account constraints, card payment protection, recurrence cancellation, undo, and snapshot retention.
- [ ] **Step 6: Commit** `Permita excluir logicamente e restaurar registros`.

### Task 5: Add undo snackbars to delete flows

**Files:**
- Modify: `lib/presentation/organiza_app.dart`
- Modify: relevant page widget tests under `test/widget/`
- Modify: relevant golden only if a verified visual change affects it

**Interfaces:** A shared state helper presents a pt-BR snackbar with an `Desfazer` action for successful user-confirmed deletions; the action calls the matching store restore method.

- [ ] **Step 1: Add failing widget tests** for deleting and undoing a transaction, task, and shopping item; assert the item disappears, the snackbar offers undo, and activation restores it.
- [ ] **Step 2: Add the same shared undo behavior** to existing transaction, account, budget, subscription, goal, investment, task, and shopping deletion handlers. Keep the snackbar duration short and consistent; do not add a permanent purge UI.
- [ ] **Step 3: Run focused widget tests** in light/dark themes and narrow mobile layout.
- [ ] **Step 4: Commit** `Ofereça desfazer exclusões na interface`.

### Task 6: Complete phase validation and report

**Files:**
- Modify: `docs/implementation/RELATORIO_FASE_2_3.md`
- Modify: `docs/implementation/PROGRESSO_V3.md`
- Modify: `docs/feature_matrix.md`
- Modify: `docs/change_log.md`
- Modify: `docs/known_good_state.md`
- Modify: `docs/DECISIONS.md`
- Modify: this plan

- [ ] **Step 1: Run** `flutter analyze --no-pub`, full `flutter test --no-pub --coverage`, Windows integration tests, and `git diff --check`; record actual results and compare against the 184-test baseline.
- [ ] **Step 2: Update docs** with schema 19, audit/undo behavior, actual validation, unsupported device checks, and unresolved risks.
- [ ] **Step 3: Re-run focused and full validation** after documentation/fixture changes where relevant; ensure no tombstone has leaked into normal views or been omitted from backup.
- [ ] **Step 4: Request an independent review** of the final diff; fix every important finding and document any minor deferral.
- [ ] **Step 5: Create an isolated draft PR** based on the Phase 2.2 branch, then wait for Windows/Ubuntu CI green before the next schema.

## Acceptance

- All ten tables have populated `updated_at` and nullable `deleted_at` at schema 19.
- v1 and v18 migration fixtures preserve balances, row counts, and referential integrity.
- Every normal read hides deleted rows, while backup/restore keeps them.
- Current deletions are logical, financial totals update immediately, and snackbar undo restores the record (and canceled salary series where applicable).
- `flutter analyze`, full tests, Windows integration tests, independent review, and PR CI pass; actual nonvalidated device/platform conditions are explicit in the report.
