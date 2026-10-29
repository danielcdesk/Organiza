# Relatório de Fase 0 — 29/10/2026

1. **Resumo**

   Preparada a fundação do V3: CI em Windows/Ubuntu, builds manuais, Dependabot, lints, relógio injetado e gerador determinístico de volume. O produto continua local-first e os dados instalados do usuário não foram acessados. As fases seguintes e os itens funcionais da auditoria permanecem pendentes.

2. **Arquivos alterados/criados**

   - `.github/workflows/ci.yml`, `.github/workflows/build.yml`, `.github/dependabot.yml`, `.gitignore`, `analysis_options.yaml`.
   - `test/support/seed_generator.dart`, `test/unit/support/seed_generator_test.dart`, `test/widget/ui_clock_test.dart` e chamadores existentes dos diálogos nos testes.
   - Páginas em `lib/presentation`: transações, orçamento, cartões, diálogos, metas, shell, componentes da visão geral, relatórios e assinaturas receberam o relógio controlado; outros componentes receberam ajustes const exigidos pelos lints.
   - README, decisões, matriz, estado conhecido, notas 0.9.0, dossiê e documentos de implementação/contrato.

3. **Migrações**

   Nenhuma. Schema 16 preservado; versão do produto mantida em 0.9.0+13 porque esta fase ainda não distribui uma nova release.

4. **Comandos executados e resultado real**

   - Linha de base: `flutter pub get`, `flutter analyze` sem problemas e `flutter test --reporter expanded`: **108 aprovados**.
   - Regressões de data e massa observadas falhando antes da implementação; testes específicos aprovados depois.
   - `flutter analyze --no-pub`: sem problemas com os três novos lints.
   - `flutter test --no-pub --coverage`: **116 aprovados**; LCOV com **6.282/9.362 linhas (67,10%)**.
   - `flutter test integration_test -d windows --no-pub`: **2 fluxos aprovados**, com compilação Debug Windows; telas 1366×768 e 390×844.
   - `git diff --check`: limpo; busca de `DateTime.now(` em `lib/presentation`: sem ocorrências.
   - O gerador insere 10 mil registros em memória em transação e valida referências de 50 mil ocorrências. Isso ainda não é benchmark de velocidade da interface; esse trabalho pertence à Fase 3.

5. **O que NÃO foi validado**

   Android físico, leitor de tela real, builds manuais de distribuição e CI remoto ainda não executados no momento deste relatório. Goldens foram executados no Windows; não regenerados.

6. **Riscos e pendências**

   Fase 0 tem validação local aprovada. O aceite remoto exige CI verde no PR, conforme o contrato. Pagamento de fatura, backup v2, máscaras, metas e demais recursos da auditoria não estão concluídos. Nenhum binário foi publicado.

7. **Decisões registradas**

   Em `docs/DECISIONS.md`: competência/caixa do cartão, dívidas para depois, criptografia por padrão com PIN/biometria opcional, manutenção de sqlite3/ChangeNotifier sem troca opcional aprovada e correções factuais do plano.

8. **Próxima fase**

   Backup/restauração confiáveis (Fase 1), após o CI exigido. As decisões da Fase 2 e criptografia da Fase 4 já foram confirmadas pelo usuário. Não foi autorizada rede no aplicativo nem implementação de sincronização.
