# Relatório da Fase 2.2 — Faturas e pagamentos de cartão

Data: 2026-10-30. Estado: Fase 2.2 implementada e validada; PR draft aberto e CI verde. O build Android local não foi executado porque este ambiente não tem Android SDK.

## 1. Resumo

Schema 18 registra categorias das compras, ciclos/faturas e pagamentos vinculados a movimentos de conta. Compras entram nos relatórios e orçamentos pela data e categoria da compra; parcelas definem os vencimentos de caixa. Pagamentos reduzem a conta e o saldo da fatura, sem contar uma segunda despesa por categoria. A projeção navegável desconta obrigações vencidas, inclui atrasos desde hoje e destaca marcações antigas que não criam débitos bancários. Dívidas e financiamentos continuam adiados.

## 2. Arquivos

Banco/migração e snapshots: `lib/database/app_database.dart`, `lib/data/local_repository.dart`, `lib/domain/models.dart`. Regras e persistência: `lib/domain/card_invoice_rules.dart`, `lib/domain/balance_projection.dart`, `lib/domain/financial_rules.dart`, `lib/application/organiza_store.dart`. Interface: `lib/presentation/cards_page.dart`, `lib/presentation/dialogs.dart`, `lib/presentation/organiza_app.dart`, `lib/presentation/reports_page.dart`, `lib/presentation/budgets_page.dart`, `lib/presentation/dashboard_page.dart`, `lib/presentation/overview_widgets.dart`. Exportação: `lib/services/report_export_service.dart`. Regras: `docs/financial_rules.md`.

## 3. Migrações

Schema 17 → 18 preserva compras e marcações manuais antigas de parcelas; categorias são preenchidas sem alterar valores nem saldos. Faturas e pagamentos são armazenados separadamente, com pagamentos ligados à transação de conta. Fixture v1 → schema atual, migração de categorias e snapshot/restore de faturas e pagamentos são cobertos pela suíte completa. Valores continuam em centavos inteiros.

## 4. Comandos e resultados reais

- `flutter analyze --no-pub`: sem problemas.
- `flutter test --no-pub --coverage`: **184 testes aprovados**, cobertura **8.256/11.309 linhas, 73,00%**.
- `flutter test integration_test -d windows --no-pub`: **2 fluxos aprovados**, incluindo compilação Windows Debug.
- `flutter build apk --debug --no-pub`: não iniciou; Flutter reportou que não há Android SDK configurado neste ambiente.
- Testes focados de pagamento/estorno pela UI, limite liberado, marcações antigas, rollback transacional, projeção, categorias, CSV e resumos de caixa: aprovados.
- `git diff --check`: sem erros de whitespace.
- Revisão independente: quatro achados importantes corrigidos com testes; uma lacuna menor de injeção de falha durante a transação continua documentada.
- CI GitHub Actions: run **41144349736**, commit `8288b91`; análise/testes Windows, análise/testes Ubuntu e build APK Android release sem assinatura passaram.
- O primeiro build Android falhou porque o registrador gerado ainda incluía `IntegrationTestPlugin` com `--no-pub`. Conforme ERR-006 já documentado, o build foi ajustado para atualizar a resolução de plugins; a nova execução compilou o APK.
- PR draft #5 aberto e sem conflitos: https://github.com/danielcdesk/Organiza/pull/5.

## 5. Não validado

Execução Android em dispositivo/emulador. Não foi validada migração com bancos reais de usuários.

## 6. Riscos e pendências

Marcações manuais antigas de parcelas não identificavam conta nem valor; aparecem destacadas, não criam lançamentos e ficam fora do valor confirmado a pagar até conferência. Compras antigas que alterem ciclo fechado exigem confirmação explícita. Não há conexão bancária/cartão, importação de fatura ou registro de dívidas nesta fase. O gate CI da Fase 2.2 está verde; a Fase 2 completa segue pendente das demais entregas de dados.

## 7. Decisões

Competência da compra: data da compra; caixa: parcelas por vencimento. Pagamento diminui apenas o caixa e o saldo da fatura, sem duplicar despesa categorizada. Estorno reverte em conjunto pagamento e transação. Marcação antiga não cria caixa e fica explicitamente sinalizada para conferência. Dívidas/financiamentos permanecem adiados conforme decisão do usuário.

## 8. Próxima fase e perguntas

PR draft #5 da Fase 2.2 sobre a Fase 2.1 está aberto; CI Windows/Ubuntu/Android verde. Não há decisão pendente do usuário para este escopo.
