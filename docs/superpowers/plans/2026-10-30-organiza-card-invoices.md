# Organiza card invoices implementation plan

**Goal:** Track card invoices and payments without counting a purchase twice, using the user's confirmed competence and cash rules.

**Base:** Phase 2.1, schema 17, PR #4 with Windows/Ubuntu CI green. Phase 2.2 adds schema 18 in a separate branch and commit theme.

**Rules:** Card purchase appears in expense categories on its purchase date. Installments determine invoice and cash due dates. Paying an invoice reduces an account balance but does not create another categorized expense. Debts/financing remain deferred. Monetary values are integer cents. Product remains local only.

## Task 1 — schema 18 and migration

- [x] Add card purchase category/subcategory FKs, `card_invoices`, `card_invoice_payments`, and indexes in one guarded migration with a pre-v18 copy.
- [x] Backfill purchase categories without changing purchase amounts, legacy manual paid-installment flags, or account balances. Document how historical manual flags remain distinct from real payments.
- [x] Test v1/v17→v18, second open, snapshot backup/restore, row counts, balances, integrity and FK checks. Populated invoice snapshot and payment linkage pass.

## Task 2 — invoice rules and payments

- [x] Add pure invoice calculations for closing/due dates, installment totals, partial payments, overpayment prevention and status.
- [x] Add a system marker to payment transactions. Store payment plus invoice payment record atomically; make it idempotent for retries. Prevent payment from appearing as a category expense in reports.
- [x] Ensure a closed invoice does not silently change after editing/removing an old purchase; require explicit confirmation for historical purchases that alter closed cycles. Purchases cannot be edited/deleted through the current UI.
- [x] Test payment, partial payment, cancellation/reversal, rollback and projection at due date without double subtraction. Payment, partial payment, reversal, overpayment, DB rollback and projection tests pass.

## Task 3 — reports and UI

- [x] Add purchase-category selection and invoice list/detail/payment flows in the card UI.
- [x] Count purchases by purchase date in category reports; show invoice due obligations in balance projection. Update CSV and budget totals consistently.
- [x] Document numerical examples in `docs/financial_rules.md`; add widget and integration tests for purchase categories, projection, payments, and reports.

## Task 4 — gate

- [ ] Run analysis, full tests with coverage, migration fixtures, Windows integration and Android build. Local Android SDK is unavailable; CI release build is the remaining Android build gate.
- [ ] Review important findings, produce 8-section phase report, push isolated draft PR based on Phase 2.1 and verify Windows/Ubuntu CI before schema 19.
