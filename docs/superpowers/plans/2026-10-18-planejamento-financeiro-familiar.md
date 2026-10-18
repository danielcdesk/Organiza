# Planejamento financeiro familiar Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Incorporar ao Organiza os conceitos da planilha mensal: essencialidade, planejamento de receitas/despesas, reserva de emergência, indicadores, dívidas e contas recorrentes.

**Architecture:** O banco continua sendo a fonte local; regras de cálculo ficam em `lib/domain/` puras e testáveis; `OrganizaStore`/`LocalRepository` permanecem fachadas para a UI. O primeiro bloco usa schema 20, o segundo apenas preferências locais, e o terceiro usa schema 21. Cada bloco é entregue e testado antes do próximo.

**Tech Stack:** Flutter/Dart, SQLite via `sqlite3`, `Clock` injetável, testes unitários/widget existentes.

**Spec:** `docs/superpowers/specs/2026-10-18-planejamento-financeiro-familiar-design.md`

## Global Constraints

- Valores monetários são centavos inteiros.
- Datas de negócio são civis e serializadas como `yyyy-MM-dd`.
- Escritas que alteram múltiplas linhas usam `AppDatabase.transaction`.
- Migrações são idempotentes, partem do schema 1 nos testes e atualizam `_backupTables`.
- Não armazenar número completo de cartão, CVV, senhas ou conteúdo financeiro em logs.
- Manter a aparência existente e textos pt-BR.

## Review Focus

- Categorias antigas sem classificação não podem desaparecer dos totais; testar migração e fallback “não classificada”.
- Receita sem fonte e lançamento de transferência não podem afetar taxa de poupança incorretamente; testar ambos.
- Média da reserva deve ignorar mês incompleto e respeitar fevereiro/ano bissexto; testar fronteiras civis.
- Parcela de dívida não pode contar principal duas vezes; testar principal, juros e confirmação.
- Alterar/excluir obrigação recorrente não pode apagar lançamentos históricos; testar vínculo e transação.

---

### Task 1: Modelo de planejamento e classificação

**Files:**
- Modify: `lib/domain/models.dart` (`FinanceCategory`, `TransactionRecord`)
- Create: `lib/domain/financial_planning.dart`
- Test: `test/unit/domain/financial_planning_test.dart`

**Interfaces:**
- Produces `enum ExpenseEssentiality { essential, nonEssential, unclassified }`.
- Produces `MonthlyFinancialPlan summarize({required Iterable<TransactionRecord> transactions, required Iterable<FinanceCategory> categories, required DateTime month, required Set<String> excludedEssentialCategoryIds})`.
- `MonthlyFinancialPlan` exposes `incomeInCents`, `essentialExpensesInCents`, `nonEssentialExpensesInCents`, `unclassifiedExpensesInCents`, `surplusInCents`, `savingsRateBasisPoints`.

- [ ] Write failing tests for category fallback, transfer exclusion, source-less income, and cent-accurate totals.
- [ ] Run `flutter test --no-pub test/unit/domain/financial_planning_test.dart` and observe the expected missing API failure.
- [ ] Implement the enum, summary value object, category lookup fallback, and pure calculation.
- [ ] Rerun the focused test and then `flutter test --no-pub`.
- [ ] Commit `feat: add monthly financial planning rules`.

### Task 2: Schema 20 and category/source persistence

**Files:**
- Modify: `lib/database/app_database.dart`, `lib/data/local_repository.dart`, `lib/application/organiza_store.dart`
- Modify: `lib/domain/models.dart`
- Test: `test/unit/data/database_migration_test.dart`, `test/unit/application/store_actions_test.dart`

**Interfaces:**
- Add `essentiality` to finance categories and optional `incomeSource`/`essentialityOverride` to transactions.
- Add repository/store methods `setFinanceCategoryEssentiality(String categoryId, ExpenseEssentiality value)` and transaction editing support for `incomeSource`/override.

- [ ] Add migration-from-v1 assertions for the new nullable/default columns and backup table compatibility.
- [ ] Run migration tests and observe failure before implementation.
- [ ] Implement schema 20 with idempotent `ALTER TABLE`, row-preserving defaults, loaders/writers, and transactional store actions.
- [ ] Add widget controls to category and transaction dialogs without changing the existing layout structure.
- [ ] Run migration, store, widget, analyze, and full tests.
- [ ] Commit `feat: persist planning classifications and income sources`.

### Task 3: Monthly planning screen and dashboard summary

**Files:**
- Create: `lib/presentation/monthly_planning_page.dart`
- Modify: `lib/presentation/organiza_app.dart`, navigation/sidebar files, `lib/presentation/dashboard_page.dart`
- Modify: `docs/feature_matrix.md`, `docs/technical_dossier.md`, `docs/change_log.md`
- Test: `test/widget/monthly_planning_page_test.dart`, update `test/widget/dashboard_page_test.dart` without changing goldens

**Interfaces:**
- `MonthlyPlanningPage(store: OrganizaStore, month: DateTime, hideValues: bool, onMonthChanged: ValueChanged<DateTime>)`.

- [ ] Write widget tests for totals, month switch, essentiality labels, and hidden values.
- [ ] Run focused widget tests to verify they fail because the route/page is absent.
- [ ] Implement the page and route using existing panels/tokens; add a compact dashboard card linked to reports/planning.
- [ ] Run widget/golden tests and verify no golden image changes.
- [ ] Commit `feat: add monthly planning view`.

### Task 4: Emergency reserve and financial indicators

**Files:**
- Create: `lib/domain/financial_health.dart`
- Modify: `lib/application/organiza_store.dart`, settings/planning UI, `lib/domain/financial_planning.dart`
- Test: `test/unit/domain/financial_health_test.dart`, `test/widget/financial_health_test.dart`
- Modify: `docs/financial_rules.md`, `docs/feature_matrix.md`, `docs/change_log.md`

**Interfaces:**
- `EmergencyReserve calculateEmergencyReserve({required List<MonthlyFinancialPlan> completeMonths, int targetMonths = 6, Set<String> excludedCategoryIds = const {}})`.
- `FinancialHealthIndicators calculateHealth({required MonthlyFinancialPlan plan, required int investmentsInCents, required int reserveBalanceInCents})`.

- [ ] Add failing tests for three complete months, incomplete current month, leap-year dates, zero income, and negative surplus.
- [ ] Run focused tests and observe failure.
- [ ] Implement pure calculations and persisted settings for target months/category exclusions.
- [ ] Add UI cards for emergency reserve target/progress, savings rate, essential-income ratio, and investment target.
- [ ] Run full tests and analyze.
- [ ] Commit `feat: add emergency reserve and financial health indicators`.

### Task 5: Schema 21 debt model

**Files:**
- Modify: `lib/domain/models.dart`, `lib/database/app_database.dart`, `lib/data/local_repository.dart`, `lib/application/organiza_store.dart`
- Create: `lib/domain/debt_rules.dart`
- Test: `test/unit/domain/debt_rules_test.dart`, `test/unit/data/database_migration_test.dart`, `test/unit/application/store_actions_test.dart`

**Interfaces:**
- `Debt` fields: `id`, `name`, `originalPrincipalInCents`, `outstandingPrincipalInCents`, `interestRateBasisPoints`, `installmentAmountInCents`, `firstDueOn`, `installmentsRemaining`, `accountId`, `category`, `isActive`, `createdAt`.
- `DebtRules.splitInstallment(total, principal, interest)` and `DebtRules.nextDueDate(...)`.
- Store methods `addDebt`, `editDebt`, `deleteDebt`, `recordDebtInstallment`, `undoDebtInstallment`.

- [ ] Add migration tests from schema 1 and tests proving principal is not counted as a second expense while interest is.
- [ ] Run them red.
- [ ] Implement tables/indexes, transactional CRUD, installment materialization and undo.
- [ ] Add debt dialog/page and projection integration.
- [ ] Run full tests and analyze.
- [ ] Commit `feat: track debts and installments`.

### Task 6: Schema 21 recurring obligations

**Files:**
- Modify: `lib/domain/models.dart`, `lib/database/app_database.dart`, `lib/data/local_repository.dart`, `lib/application/organiza_store.dart`, `lib/domain/balance_projection.dart`
- Create: `lib/domain/recurring_obligation_rules.dart`
- Test: `test/unit/domain/recurring_obligation_rules_test.dart`, `test/unit/domain/balance_projection_test.dart`, `test/unit/application/store_actions_test.dart`

**Interfaces:**
- `RecurringObligation` fields: `id`, `name`, `category`, `accountId`, `estimatedAmountInCents`, `period`, `billingDay`, `nextDueOn`, `isActive`, `createdAt`.
- Store methods `addRecurringObligation`, `editRecurringObligation`, `deleteRecurringObligation`, `confirmRecurringObligation`.

- [ ] Add failing tests for month-end adjustment, variable estimated amount, inactive obligations, and deleting an obligation without deleting history.
- [ ] Run focused tests red.
- [ ] Implement schema/table/index, projection integration, transactional CRUD and confirmation links.
- [ ] Add UI under Organization with edit/delete confirmation and undo for confirmation.
- [ ] Run full tests, analyze, and integration tests when the Windows toolchain is available.
- [ ] Commit `feat: add recurring obligations and projection`.

### Task 7: Documentation and release verification

**Files:**
- Modify: `docs/architecture.md`, `docs/financial_rules.md`, `docs/feature_matrix.md`, `docs/technical_dossier.md`, `docs/change_log.md`, `docs/release_checklist.md`

- [ ] Document schema 20/21, calculation decisions, backup implications, and no-double-counting rules.
- [ ] Run `flutter analyze`, `flutter test`, and `flutter test integration_test -d windows` when dependencies permit.
- [ ] Run `git diff --check` and confirm no golden files changed.
- [ ] Commit `docs: document financial planning modules`.
