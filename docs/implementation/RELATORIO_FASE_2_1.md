# Relatório da Fase 2.1 — Categorias com vínculo estável

Data: 2026-10-30. Estado: implementação local validada; CI do PR pendente.

## 1. Resumo

O schema 17 vincula lançamentos, orçamentos e assinaturas a categorias por ID, preservando o texto legado para compatibilidade. Renomear uma categoria passa a refletir no histórico; arquivar retira a categoria dos novos cadastros sem perder registros antigos. Metas usam o vocabulário próprio de categorias de metas. Configurações oferece renomeação e arquivamento das categorias personalizadas.

## 2. Arquivos

Banco e migração: `lib/database/app_database.dart`. Modelo e aplicação: `lib/domain/models.dart`, `lib/data/local_repository.dart`, `lib/application/organiza_store.dart`. Interface: `lib/presentation/basic_pages.dart`, `lib/presentation/organiza_app.dart`. Testes: `test/unit/data/category_migration_test.dart`, `category_repository_test.dart`, `goal_category_integrity_test.dart`, `test/unit/application/category_store_test.dart`, `test/widget/category_management_test.dart`, `test/support/seed_generator.dart`. Documentos: `docs/DECISIONS.md`, `docs/technical_dossier.md`, `docs/feature_matrix.md`, `docs/implementation/PROGRESSO_V3.md` e plano da Fase 2.1.

## 3. Migrações

Schema **16 → 17** em transação, com cópia `pre-v17` antes da migração em arquivo. Os IDs são preenchidos por nome e tipo; categorias históricas ausentes são criadas. Transferências ficam sem ID de categoria. Metas recebem `goal_category_name` referenciando `goal_categories(name)`, com atualização em cascata. Testes cobrem **v1 → v17** e **v16 → v17**, saldo e contagens preservados, `integrity_check`, `foreign_key_check` e segunda abertura sem mudança. A gravação em schemas antigos continua possível para os testes de migração.

## 4. Comandos e resultados reais

- `flutter analyze --no-pub`: sem problemas.
- `flutter test --no-pub --coverage`: **161 testes aprovados** (antes desta migração: 151), cobertura **7.353/10.636 linhas, 69,13%**.
- Testes focados de migração, repositório, metas e interface: aprovados.
- `flutter test integration_test -d windows --no-pub`: **2 fluxos aprovados**.
- `git diff --check`: sem erros.
- Revisão independente encontrou três problemas importantes, corrigidos com testes: edição de lançamento arquivado, edição de assinatura arquivada e divisão salarial alterada por categoria de receita homônima. Uma tentativa de recriar categoria arquivada agora recebe erro controlado.

## 5. Não validado

Execução em Android físico ou emulador. Bancos de usuários fora das versões geradas pelos testes. Pacote de distribuição desta fase.

## 6. Riscos e pendências

Os campos de texto permanecem durante a transição e precisam continuar sincronizados por todo novo ponto de escrita. A migração de categorias é uma parte da Fase 2; cartões/faturas e os demais temas ainda não foram iniciados. Não há medição de desempenho específica desta migração.

## 7. Decisões

Metas mantêm tabela de categorias própria; `goal_category_name` referencia essa tabela em vez de associar metas a categorias de receita/despesa. Ver `docs/DECISIONS.md`. Compras do cartão permanecem por competência, pagamento sem duplicar despesa, e dívidas adiadas conforme decisão do usuário.

## 8. Próxima fase e perguntas

Após revisão e CI verde, iniciar a Fase 2.2, schema 18 de faturas e pagamentos de cartão. As decisões sobre competência, caixa e dívidas já foram confirmadas pelo usuário; não há nova pergunta para iniciar esse tema.
