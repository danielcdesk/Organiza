# Estratégia de testes

## Fundação V3 — 29/10/2026

Linha de base: 108 testes Flutter. Após relógio injetado e gerador: 116 testes, análise sem problemas, cobertura LCOV de 67,10% (6.282/9.362 linhas) e 2 fluxos de integração Windows aprovados. `test/support/seed_generator.dart` produz dados reproduzíveis por semente/Clock, séries completas, cartões e compras parceladas. Há inserção de 10 mil transações e validação de referências de 50 mil; não confundir com benchmark de abertura da interface, reservado à Fase 3.

CI usa Windows para a suíte completa (incluindo goldens) e Ubuntu para unitários, ambos com análise e cobertura. Builds são acionados manualmente em `build.yml`: Windows release e APK Android release **sem assinatura de distribuição**. O APK é artefato de compilação, não atualização oficial instalável. Execuções remotas devem ser registradas separadamente das locais.

1. Testes unitários para cálculos financeiros, validações e migrações.
2. Testes de banco para constraints, consultas e atualização de schema.
3. Testes de widget para atalhos, estados vazios, formulários e acessibilidade básica.
4. Testes de integração para o fluxo completo e reinicialização.

Execute `flutter analyze`, `flutter test` e `flutter test integration_test -d windows` em cada alteração relevante. Os fluxos de integração usam banco SQLite em memória, fixam viewports de 1366×768 e 390×844, verificam erros de renderização e geram capturas em `build/qa/`. Antes de um release, rode `flutter build windows --release` e `flutter build apk --release` (sem `--no-pub` após os testes integrados), confira o conteúdo do ZIP Windows e valide assinatura/versão do APK com `apksigner` e `aapt`. O viewport compacto no Windows não substitui um teste de instalação em Android físico.

Volume-alvo futuro: 10.000 transações e 1.000 tarefas sem carregar dados desnecessários em memória.
