# Relatório da Fase 2.3 — Auditoria e exclusão lógica

Data: 2026-10-30. Estado: implementação concluída e validada; PR draft aberto, CI verde.

## 1. Resumo

Schema 19 adiciona `updated_at` e `deleted_at` às dez entidades previstas. Migrações v1/v18, triggers de auditoria, leituras ativas e snapshots com tombstones estão cobertos. Exclusões do app agora são lógicas; a snackbar “Desfazer” restaura o registro, e exclusão de ocorrência salarial recorrente também restaura sua agenda. Nenhuma sincronização ou rede foi introduzida. Expurgo definitivo e política de retenção continuam adiados.

## 2. Arquivos principais

- Persistência e migração: `lib/database/app_database.dart`, `lib/data/local_repository.dart`, `lib/domain/models.dart`.
- Casos de uso e validação: `lib/application/organiza_store.dart`.
- Interface: `lib/presentation/organiza_app.dart`.
- Testes: `test/unit/data/database_migration_test.dart`, `test/unit/data/soft_delete_repository_test.dart`, `test/unit/application/store_actions_test.dart`, `test/widget/soft_delete_undo_test.dart`.
- Registro técnico: `docs/technical_dossier.md` (seção 20).

## 3. Migração e comportamento

O upgrade 18→19 é aditivo; linhas existentes recebem `updated_at = created_at` e `deleted_at = NULL`. Triggers conhecidos mantêm `updated_at`. As consultas usuais ocultam linhas excluídas; snapshot, exportação e restauração preservam todas as linhas, inclusive tombstones. A exclusão recebe data UTC do relógio injetado do store. O enum de entidades limita tabelas autorizadas para SQL dinâmico.

Confirmações de exclusão preservam suas validações existentes. Pagamentos de cartão continuam exigindo estorno pela fatura. Excluir um salário recorrente cancela a agenda; “Desfazer” dentro dos seis segundos restaura ambos atomicamente. Não há ação para expurgo permanente.

## 4. Comandos e resultados locais

- `flutter analyze --no-pub`: sem problemas.
- `flutter test --no-pub --coverage`: **194 testes aprovados**, cobertura de linhas **8.374/11.387 (73,54%)**.
- `flutter test integration_test -d windows --no-pub`: **2 fluxos aprovados**, incluindo compilação Windows Debug.
- `flutter test --no-pub test/widget/soft_delete_undo_test.dart`: **2 testes aprovados**, exercitando tarefa, transação e item de compras em largura de 390 px.
- `flutter test --no-pub test/unit/data/soft_delete_repository_test.dart test/unit/application/store_actions_test.dart test/unit/application/card_invoice_payment_test.dart test/unit/services/backup_coordinator_test.dart`: **33 testes aprovados**.
- `git diff --check`: sem erros.
- Cobertura comparada à Fase 2.2: 194 testes, contra 184; 73,54%, contra 73,00%.

## 5. CI e revisão

Branch `codex/organiza-v3-fase-2-3`, baseada no head da Fase 2.2 (`4b84b573`). PR draft #6 está aberto contra `codex/organiza-v3-fase-2-2`: https://github.com/danielcdesk/Organiza/pull/6. GitHub Actions run **41148582388** passou nos jobs de análise/testes Ubuntu, análise/testes Windows e APK Android release sem assinatura. A revisão independente não encontrou achados críticos/importantes. A recomendação menor sobre o relógio em wrappers antigos foi resolvida: os wrappers foram removidos, e o estorno de cartão também usa o relógio UTC injetado.

## 6. Não validado e riscos

Não houve teste em dispositivo Android físico nem migração sobre banco financeiro de usuário. Os testes de widget usaram largura móvel de 390 px e altura maior que um aparelho para deixar os controles visíveis; o layout móvel de altura comum continua coberto pelo teste de navegação existente, mas o novo fluxo de exclusão não foi percorrido em 390×844. Sem expurgo, tombstones continuam ocupando espaço no banco e nos backups. A tabela de cartões e compras de cartão já têm auditoria/filtro genérico, mas atualmente não expõem ações de exclusão no produto.

## 7. Decisões mantidas

Compras no cartão continuam categorizadas pela data da compra e pagamento reduz apenas o caixa. Dívidas e financiamentos permanecem adiados. A Fase 2.3 não altera esses comportamentos nem as decisões de criptografia da Fase 4.

## 8. Próxima etapa

A Fase 2.3 passou no CI. A Fase 2 completa ainda não está concluída; a próxima migração pode seguir pelo fluxo de revisão do PR #6.
