# Estratégia de testes

1. Testes unitários para cálculos financeiros, validações e migrações.
2. Testes de banco para constraints, consultas e atualização de schema.
3. Testes de widget para atalhos, estados vazios, formulários e acessibilidade básica.
4. Testes de integração para o fluxo completo e reinicialização.

Execute `flutter analyze`, `flutter test` e `flutter test integration_test -d windows` em cada alteração relevante. Os fluxos de integração usam banco SQLite em memória, fixam viewports de 1366×768 e 390×844, verificam erros de renderização e geram capturas em `build/qa/`. Antes de um release, rode `flutter build windows --release` e `flutter build apk --release` (sem `--no-pub` após os testes integrados), confira o conteúdo do ZIP Windows e valide assinatura/versão do APK com `apksigner` e `aapt`. O viewport compacto no Windows não substitui um teste de instalação em Android físico.

Volume-alvo futuro: 10.000 transações e 1.000 tarefas sem carregar dados desnecessários em memória.
