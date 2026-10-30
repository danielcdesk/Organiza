# Organiza category foreign keys Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make category renames preserve every transaction, budget and subscription association, while keeping the existing goal category vocabulary.

**Architecture:** Schema 17 adds nullable foreign keys beside the legacy text columns. The database resolves an ID at the write boundary and reads the current category name through a join, falling back to legacy text only when the ID is absent. Goals keep their distinct `goal_categories` table and receive a foreign key to its name; they are not finance income or expense categories.

**Tech Stack:** Flutter/Dart, sqlite3 3.5.2, ChangeNotifier, existing test and migration helpers.

**Spec:** `docs/product/ORGANIZA_MEGA_PROMPT_V3.md`, section 5, Phase 2.1; `docs/financial_rules.md`; `docs/DECISIONS.md`.

## Global Constraints

- Local only; no network, Drift or replacement of ChangeNotifier.
- Monetary values remain integer cents; migration must preserve every consolidated balance.
- Schema increments from 16 to 17 once. Migration runs in a transaction, is idempotent, and keeps a validated pre-v17 backup.
- Write operations touching multiple rows use `AppDatabase.transaction`.
- Test v1→17 and v16→17 with realistic data, second open, `integrity_check` and `foreign_key_check`.
- User-facing text remains pt-BR.

## Review Focus

- An unknown historical category must get a valid FK without losing its original name; pin in Task 1 test.
- Income and expense categories with the same name must never cross-link; pin in Task 1 test.
- A renamed category must display under the new name in old reports and budgets; pin in Task 2 test.
- A category archive must prevent new selection while old records stay readable; pin in Task 3 test.
- A failed multi-row category write must roll back both inserted category and transaction; pin in Task 2 test.

---

### Task 1: Schema 17 migration and backfill

**Files:** Modify `lib/database/app_database.dart`, `docs/DECISIONS.md`, `docs/technical_dossier.md`; create `test/unit/data/category_migration_test.dart`.

**Interfaces:** `AppDatabase.currentSchemaVersion == 17`; `AppDatabase.openInMemoryAtVersionForTest(16)` remains usable. New columns: `transactions.category_id`, `transactions.subcategory_id`, `budgets.category_id`, `subscriptions.category_id`, `finance_categories.archived_at`, `financial_goals.goal_category_name`. `goal_category_name` references `goal_categories(name) ON UPDATE CASCADE` because goals use a separate vocabulary.

- [x] Write a failing v16 fixture with income/expense categories sharing a name, an unknown historical category and subcategory, a budget, subscription and goal. Assert IDs, balance and counts after opening as v17.
- [x] Run the focused test to observe failure against schema 16.
- [x] Add guarded schema 17 DDL and backfill inside `_applyMigrations`, using the existing `_migrate` transaction and pre-v17 copy. Create missing categories/subcategories from historical text before assigning IDs. Transfer keeps null category IDs. Add indexes for date and FK lookup.
- [x] Add v1→17 and second-open idempotency assertions, integrity and FK checks, and unchanged balance.
- [x] Run focused tests and full `flutter analyze`/`flutter test` (153 passed); commit the migration separately in Portuguese.

### Task 2: Authoritative category IDs at the repository boundary

**Files:** Modify `lib/domain/models.dart`, `lib/database/app_database.dart`, `lib/data/local_repository.dart`, `lib/application/organiza_store.dart`; create `test/unit/data/category_repository_test.dart`.

**Interfaces:** Add optional `categoryId` and `subcategoryId` to `TransactionRecord`, optional `categoryId` to `Budget` and `Subscription`. Database insert/update resolves IDs and canonical names in one transaction, including nested calls from installment/recurrence writes. `loadTransactions`, `loadBudgets` and `loadSubscriptions` join category names, falling back to text for null IDs. Add `renameFinanceCategory(id, newName)` and `archiveFinanceCategory(id)` through repository/store.

- [ ] Write failing tests for new writes, historical rename, case/accent matching, nested transaction rollback and archive behavior.
- [ ] Observe RED and implement one category resolution path for all writes. Do not put SQL or finance rules in widgets.
- [ ] Make nested transactions safe with SQLite savepoints if existing store callers already own a transaction; test rollback at both levels.
- [ ] Run focused tests and full analysis/suite; commit separately.

### Task 3: Category management UI and goal category integrity

**Files:** Modify `lib/presentation/basic_pages.dart`, `lib/presentation/organiza_app.dart`, `lib/database/app_database.dart`, `lib/data/local_repository.dart`, `lib/application/organiza_store.dart`; add `test/widget/category_management_test.dart`.

**Interfaces:** Settings allows rename/archive of finance categories; archived categories are hidden from new-entry pickers but preserved in historical joins. `financial_goals.goal_category_name` is written with the existing goal category selected and loaded through that FK. Goal category rename (if offered) updates the distinct `goal_categories` table with `ON UPDATE CASCADE`.

- [ ] Write failing widget/data tests for a finance category rename reflected in old transaction and budget, archive hiding it from a new form, and a goal remaining linked to its distinct goal category.
- [ ] Implement compact management UI with pt-BR labels and confirmation for archive; keep text/ID resolution in data layer.
- [ ] Run focused tests, full analysis/suite and Windows integration; commit separately.

### Task 4: Phase 2.1 gate

**Files:** Update `docs/feature_matrix.md`, `docs/technical_dossier.md`, `docs/implementation/PROGRESSO_V3.md`.

- [ ] Record the code-vs-spec goal-category divergence and migration counts in docs.
- [ ] Run `flutter analyze`, `flutter test --coverage` and migration tests on v1/v16 fixtures; verify unchanged balance and `git diff --check`.
- [ ] Request code review, fix Important findings, then push to an isolated branch/PR and verify Windows/Ubuntu CI before the next schema theme.
