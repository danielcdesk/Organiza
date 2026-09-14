# Estratégia de testes

1. Testes unitários para cálculos financeiros, validações e migrações.
2. Testes de banco para constraints, consultas e atualização de schema.
3. Testes de widget para atalhos, estados vazios, formulários e acessibilidade básica.
4. Testes de integração para o fluxo completo e reinicialização.

Execute `flutter analyze`, `flutter test` e `flutter test integration_test -d windows` em cada alteração relevante. O fluxo de integração usa banco SQLite em memória, fixa o viewport em 1366×768, verifica erros de renderização e captura o dashboard e Cartões em `build/qa/`. Antes de um release Windows, rode também `flutter build windows --release` e registre o resultado na baseline.

Volume-alvo futuro: 10.000 transações e 1.000 tarefas sem carregar dados desnecessários em memória.
