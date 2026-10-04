# Organização dos testes

Os testes ficam separados pelo tipo de responsabilidade:

- `unit/domain/`: regras puras e cálculos financeiros.
- `unit/application/`: ações e comportamento do store.
- `unit/data/`: banco, migrações e persistência.
- `unit/services/`: serviços locais, como backup.
- `widget/`: telas, diálogos, layout e componentes Flutter.
- `../integration_test/`: fluxos completos executados contra o app.

O Flutter continua descobrindo todos os arquivos recursivamente com `flutter test`.
