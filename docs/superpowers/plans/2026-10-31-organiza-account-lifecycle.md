# Organiza Account Lifecycle Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add schema 20 account type, archival state, net-worth inclusion, and reserved BRL currency while keeping archived-account history intact.

**Architecture:** Add the four account fields with an additive migration and typed domain model. Keep all non-deleted accounts loaded for history/account screens, expose active account options separately, and validate all new transaction writes against active accounts. Archive state is independent from logical deletion. Net-worth account balances are grouped by currency to avoid cross-currency summation.

**Tech Stack:** Flutter/Dart, sqlite3, existing Flutter `ChangeNotifier` store and widgets.

**Spec:** `docs/superpowers/specs/2026-10-31-organiza-account-lifecycle-design.md`; V3 requirement `docs/product/ORGANIZA_MEGA_PROMPT_V3.md`, Phase 2.4.

## Global Constraints

- SQLite schema becomes 20 with fields and allowed values from V3 Phase 2.4.
- Existing account rows migrate to checking, active, included in net worth, and BRL.
- Multi-currency conversion is not implemented; unlike currencies are never summed.
- Archived accounts retain history and remain available for viewing, but are absent from new transaction account pickers.
- Existing financial rules and balances must remain identical after migration.
- No new dependencies, network access, telemetry, hard deletion of linked accounts, or account sync.

## Review Focus

1. **v1 and v19 populated migrations:** preserve row counts, transactions, balances, FKs; test both fixtures.
2. **Archived accounts in transaction editing/history:** retain account labels for historical rows while excluding archived accounts from new account/destination choices; test UI and direct store validation.
3. **Archival effects:** balances, transactions, pending counts and salary schedules must remain; archive/unarchive only changes lifecycle metadata; test store behavior.
4. **Net-worth inclusion and currencies:** toggling inclusion must not alter cash balance; totals group by currency and include archived accounts only when opted in; test exact grouping.
5. **Deleted account overlap:** archived and logically deleted are distinct states; normal active-account picker must exclude both, restore must preserve archived state; test combined flags.

---

### Task 1: Prove schema 20 migration

**Files:**
- Modify `test/unit/data/database_migration_test.dart`.
- Modify `test/unit/data/database_backup_core_test.dart` or an existing versioned database fixture.

**Interfaces:** Build on existing v1 and v19 migration fixtures; `AppDatabase.currentSchemaVersion` is expected to become 20.

- [x] Add failing v19→20 assertions for columns, defaults, counts, balance and FKs; also assert the v1→current fixture reaches 20.
- [x] Run the focused migration test and confirm it fails on schema 19/missing account columns.
- [x] Implement the additive migration, SQL checks/defaults, and account row backfill in `lib/database/app_database.dart`.
- [x] Migration tests from v1 and v19 preserve original balances, row counts and integrity.
- [x] Commit changes as part of the phase implementation commits.

### Task 2: Model and repository support

**Files:**
- Modify `lib/domain/models.dart`.
- Modify `lib/database/app_database.dart`.
- Modify `lib/data/local_repository.dart`.
- Modify `test/unit/data/` account repository/migration tests.

**Interfaces:** Add `AccountType { checking, savings, wallet, investment, other }`; extend `Account` with `type`, nullable `archivedAt`, `includeInNetWorth`, and `currency`. Add repository methods for account lifecycle and include flag.

- [x] Add failing load/insert/update tests proving default BRL/checking and persisted archive/inclusion fields.
- [x] Implement typed account mapping and database writes; all new accounts use BRL and existing migration defaults remain stable.
- [x] Test archive timestamp updates and unarchive clearing while preserving account balance, ID, institution and transaction links.
- [x] Commit changes as part of the phase implementation commits.

### Task 3: Store rules and currency-safe totals

**Files:**
- Modify `lib/application/organiza_store.dart`.
- Modify `lib/domain/financial_rules.dart` only if the grouped aggregate belongs there.
- Modify `test/unit/application/store_actions_test.dart` and domain tests.

**Interfaces:** `activeAccounts` returns non-deleted, non-archived accounts; `archiveAccount(id)`, `restoreAccount(id)`, and `setAccountNetWorthIncluded(id, included)` are guarded store actions. `accountBalancesByCurrencyForNetWorth` returns `Map<String, int>` calculated from opening balances and transactions for included accounts.

- [x] Add failing store tests proving archived accounts are absent from active pickers, archive/unarchive preserves balance/history, and toggling inclusion never changes `balance`.
- [x] Add failing grouped-total tests for mixed currency and archived inclusion cases.
- [x] Guard add/update transaction, transfers, card payments, and recurring salary against archived accounts where a new financial write is created; historical reads remain valid.
- [x] Implement the store actions and grouped-by-currency account-balance aggregate; never sum across currency codes.
- [x] Run focused store, account, card-payment and recurrence tests.
- [x] Commit changes as part of the phase implementation commits.

### Task 4: Account UI and account selectors

**Files:**
- Modify `lib/presentation/basic_pages.dart` and `lib/presentation/organiza_app.dart`.
- Modify `lib/presentation/dialogs.dart`.
- Modify account selector call sites in `lib/presentation/`.
- Add/modify widget tests in `test/widget/`.

**Interfaces:** `AccountDialog` collects a typed account kind and saves BRL implicitly. `AccountsPage` displays type, active/archive state and net-worth inclusion; actions allow archive, reactivate, inclusion toggle, edit, balance adjustment and existing guarded delete. Transaction and transfer selectors receive `activeAccounts` for creation; historical edit retains its current archived account option only for the unchanged historical row.

- [x] Add widget tests proving account kind persists and archive/reactivate changes state without losing balance/history; store tests cover exclusion from new writes.
- [x] Add fields, status, and reversible actions to account UI with pt-BR labels; preserve mobile layout and themes.
- [x] Switch creation selectors to active accounts while retaining historical account choices needed to edit other fields on an archived-account transaction.
- [x] Run focused account, transaction, and mobile widget tests.
- [x] Commit changes as part of the phase implementation commits.

### Task 5: Documentation and phase validation

**Files:**
- Modify `docs/technical_dossier.md`, `docs/implementation/PROGRESSO_V3.md`, `docs/feature_matrix.md`, `docs/change_log.md`, `docs/known_good_state.md`, `docs/DECISIONS.md`.
- Create `docs/implementation/RELATORIO_FASE_2_4.md`.
- Update this plan.

- [x] Record schema 20 and exact archive/currency behavior in the technical dossier.
- [x] Run analysis, full coverage suite, Windows integration and `git diff --check`; record 203 tests and 74,78% against the 194-test Phase 2.3 baseline.
- [x] Run an independent read-only review and cover its minor UI-test recommendation.
- [x] Prepare phase report and supporting docs.
- [x] Push `codex/organiza-v3-fase-2-4`, open draft PR #7 targeting `codex/organiza-v3-fase-2-3`, and wait for Windows/Ubuntu/Android CI before schema 21. CI run 41150382909 passed.
