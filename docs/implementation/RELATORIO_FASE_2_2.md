# Relatório da Fase 2.2 — Faturas e pagamentos de cartão

Data: 2026-10-30. Estado: implementação concluída localmente; PR e CI ainda pendentes. O build Android local não foi executado porque este ambiente não tem Android SDK.

## 1. Resumo

Schema 18 registra categorias das compras, ciclos/faturas e pagamentos vinculados a movimentos de conta. Compras entram nos relatórios e orçamentos pela data e categoria da compra; parcelas definem os vencimentos de caixa. Pagamentos reduzem a conta e o saldo da fatura, sem contar uma segunda despesa por categoria. A projeção desconta obrigações vencidas na data de vencimento e compensa pagamentos já feitos. Dívidas e financiamentos continuam adiados.

## 2. Arquivos

Banco/migração e snapshots: `lib/database/app_database.dart`, `lib/data/local_repository.dart`, `lib/domain/models.dart`. Regras e persistência: `lib/domain/card_invoice_rules.dart`, `lib/domain/balance_projection.dart`, `lib/domain/financial_rules.dart`, `lib/application/organiza_store.dart`. Interface: `lib/presentation/cards_page.dart`, `lib/presentation/dialogs.dart`, `lib/presentation/organiza_app.dart`, `lib/presentation/reports_page.dart`, `lib/presentation/budgets_page.dart`, `lib/presentation/dashboard_page.dart`, `lib/presentation/overview_widgets.dart`. Exportação: `lib/services/report_export_service.dart`. Regras: `docs/financial_rules.md`.

## 3. Migrações

Schema 17 → 18 preserva compras e marcações manuais antigas de parcelas; categorias são preenchidas sem alterar valores nem saldos. Faturas e pagamentos são armazenados separadamente, com pagamentos ligados à transação de conta. Fixture v1 → schema atual, migração de categorias e snapshot/restore de faturas e pagamentos são cobertos pela suíte completa. Valores continuam em centavos inteiros.

## 4. Comandos e resultados reais

- `flutter analyze --no-pub`: sem problemas.
- `flutter test --no-pub --coverage`: **175 testes aprovados**, cobertura **8.122/11.190 linhas, 72,58%**.
- `flutter test integration_test -d windows --no-pub`: **2 fluxos aprovados**, incluindo compilação Windows Debug.
- `flutter build apk --debug --no-pub`: não iniciou; Flutter reportou que não há Android SDK configurado neste ambiente.
- Testes focados de pagamentos, rollback, projeção, categorias, CSV e interface: aprovados.
- `git diff --check`: sem erros de whitespace.
- CI do PR e revisão independente: pendentes.

## 5. Não validado

Compilação Android local e execução em dispositivo/emulador. Compilação Android no CI será verificada no PR. Não foi validada migração com bancos reais de usuários.

## 6. Riscos e pendências

Faturas pagas manualmente no fluxo antigo não tinham conta nem valor e permanecem distintas de pagamentos reais. Compras antigas que alterem ciclo fechado exigem confirmação explícita. Não há conexão bancária/cartão, importação de fatura ou registro de dívidas nesta fase. O estado da fase só deve avançar após revisão e CI verde.

## 7. Decisões

Competência da compra: data da compra; caixa: parcelas por vencimento. Pagamento diminui apenas o caixa e o saldo da fatura, sem duplicar despesa categorizada. Estorno reverte em conjunto pagamento e transação. Dívidas/financiamentos permanecem adiados conforme decisão do usuário.

## 8. Próxima fase e perguntas

Criar/atualizar PR draft da Fase 2.2 sobre a Fase 2.1, concluir revisão independente e CI Windows/Ubuntu/Android. Não há decisão pendente do usuário para este escopo.
