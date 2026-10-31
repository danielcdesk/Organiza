# Relatório da Fase 2.4 — Tipo e ciclo de vida das contas

Data: 2026-10-30. Estado: implementação local validada; revisão independente concluída; CI do PR pendente.

## 1. Resumo

Schema 20 adiciona tipo de conta, data de arquivamento reversível, inclusão patrimonial e código de moeda. Contas antigas migram para corrente/ativa/incluída/BRL sem recalcular saldos ou alterar vínculos. Contas arquivadas continuam visíveis com histórico e saldo, mas não podem receber novos lançamentos, transferências ou pagamentos de fatura. Salários recorrentes precisam ser cancelados antes do arquivamento. Totais patrimoniais respeitam a inclusão de cada conta e são agrupados por moeda, sem conversão. A interface cria novas contas em BRL.

## 2. Arquivos principais

- Migração, mapeamento e persistência: `lib/database/app_database.dart`, `lib/data/local_repository.dart`, `lib/domain/models.dart`.
- Regras e operações: `lib/application/organiza_store.dart`, `lib/domain/financial_rules.dart`.
- Formulário, página e seletores: `lib/presentation/dialogs.dart`, `lib/presentation/basic_pages.dart`, `lib/presentation/organiza_app.dart`.
- Cobertura: testes de migração e persistência em `test/unit/data/`, regras em `test/unit/application/store_actions_test.dart` e `test/unit/domain/financial_rules_test.dart`, interface em `test/widget/account_lifecycle_test.dart`.

## 3. Migração e comportamento

O upgrade 19→20 é aditivo. `type` aceita `checking`, `savings`, `wallet`, `investment` e `other`; `archived_at` é nulo por padrão; `include_in_net_worth` é 1; `currency` é `BRL`. O backup anterior à migração usa `.pre-v20.bak`. Fixtures v1 e v19 verificam schema final, saldos, contagens e integridade.

Arquivar não remove a conta nem modifica saldo e transações. Reativar limpa `archived_at`. Edições históricas mantêm a opção de conta arquivada original, mas novas transações usam apenas contas ativas. Inclusão patrimonial não interfere no caixa e também pode ser ajustada em contas arquivadas. Códigos de moeda distintos nunca são somados entre si.

## 4. Comandos e resultados locais

- `flutter analyze --no-pub`: sem problemas.
- `flutter test --no-pub --coverage`: **203 testes aprovados**, cobertura de linhas **8.627/11.536 (74,78%)**.
- `flutter test integration_test -d windows`: **2 fluxos aprovados**, incluindo compilação Windows Debug.
- `flutter test --no-pub test/widget/account_lifecycle_test.dart`: **2 testes aprovados**, cobrindo seleção de tipo, arquivamento, reativação e inclusão patrimonial.
- `git diff --check`: sem erros.
- Comparação à Fase 2.3: 203 testes contra 194; cobertura 74,78% contra 73,54%.

## 5. Revisão e CI

Revisão independente não encontrou problemas críticos ou importantes. A recomendação menor de acrescentar teste visual de conta foi atendida em `account_lifecycle_test.dart`. O PR draft será aberto contra `codex/organiza-v3-fase-2-3`; a execução verde de CI Windows/Ubuntu/Android continua sendo gate antes de avançar para schema 21.

## 6. Não validado

Não houve migração sobre banco financeiro real nem execução em aparelho Android físico. O CI remoto desta fase ainda não terminou. Multi-moeda com edição/conversão não foi implementada: moeda é reservada, novas contas usam BRL e cada código é exibido/totalizado separadamente.

## 7. Decisões mantidas

Compras no cartão seguem pela data da compra, e o pagamento da fatura reduz somente o caixa. Dívidas e financiamentos continuam adiados. Criptografia padrão do banco, PIN e biometria opcional permanecem planejados para a Fase 4.

## 8. Próxima etapa

Esperar CI do PR draft da Fase 2.4. Não iniciar schema 21 até todos os jobs Windows, Ubuntu e Android passarem.
