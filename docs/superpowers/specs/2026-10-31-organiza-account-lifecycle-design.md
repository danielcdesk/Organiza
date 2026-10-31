# Organiza Account Lifecycle Design — Schema 20

## Intent

Implement the V3 Phase 2.4 account fields and archive lifecycle while retaining existing balances and history. This is a local-first extension of the current SQLite/`OrganizaStore` design; it adds no currency conversion or online behavior.

## Goals

- Migrate to schema 20 with `accounts.type`, `archived_at`, `include_in_net_worth`, and `currency` exactly as specified in `docs/product/ORGANIZA_MEGA_PROMPT_V3.md`.
- Initialize all existing accounts as `checking`, active, included in net worth, and `BRL`; preserve IDs, balances, institutions, and transactions.
- Keep archived accounts and their histories visible on the Accounts and transaction-history screens, but exclude them from account pickers for new transactions/transfers and reject new writes against archived accounts.
- Allow archive/unarchive and net-worth inclusion changes without changing balances or deleting historical data.
- Preserve net-worth account balance totals by currency, never summing unlike currencies. The current UI continues creating BRL accounts; no conversion or currency selector is added.

## Non-goals

- Multi-currency entry, rates, conversion, or consolidated totals across currencies.
- Net-worth time-series reporting and investment/debt valuation; those belong to later Phase 2 items.
- Hard deletion of accounts or transactions, bank integrations, and synchronization.

## Constraints

- Stay on sqlite3 and `ChangeNotifier`; no dependencies.
- Schema migration is additive and sequential from v1 and v19; preserve exact financial balances and account/transaction counts.
- Keep archived accounts in the general `store.accounts` collection so history and balances still resolve. Use an explicit active-account getter for creation workflows.
- Database stays local. User-facing strings remain pt-BR. Currency amounts remain integer cents.

## Approaches

1. **Hide archived rows from every account read.** Rejected: history, account balance, and transaction account labels would lose their account context.
2. **Keep all accounts in the repository and filter only account pickers/write validation.** Selected: the account list can show archive status and balances, while new financial writes cannot attach to an archived account. This also preserves existing history joins.
3. **Convert balances to one app-wide net-worth integer.** Rejected: schema reserves a currency code and explicitly forbids summing different currencies. Expose totals grouped by currency instead; Phase 2.6 may consume that map.

## Product calls

- Existing rows migrate as `checking`, `archived_at = NULL`, `include_in_net_worth = 1`, `currency = 'BRL'`.
- Archive remains reversible through an explicit “Arquivar/Reativar conta” action. It does not tombstone the account or its transactions.
- Keep the existing guarded logical-delete path for empty accounts as a separate action; it continues offering undo.
- Add a store getter that groups active account balances where `include_in_net_worth` is true by currency, including archived accounts when opted in. Do not produce a cross-currency scalar.
- New accounts continue to use BRL; the currency column is reserved for future support.

## Acceptance

Migration v1/v19→v20 preserves all values; archives disappear from new transaction and transfer account pickers; direct store calls cannot create/update transactions on archived accounts; archive/unarchive and include toggle preserve balance/history; grouped balance totals respect the currency boundary; analysis, full test suite, Windows integration, independent review, and PR CI pass.
