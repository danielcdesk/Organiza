# Orientações para manutenção

## Escopo do projeto

- O Organiza é um aplicativo Flutter local-first para Windows e Android.
- Dados financeiros ficam em SQLite no dispositivo. Não introduza rede, telemetria, login remoto ou sincronização sem uma decisão de produto documentada.
- Valores monetários são inteiros em centavos; datas de negócio devem ser tratadas sem depender do fuso horário do dispositivo.

## Validação obrigatória

Após mudanças em `lib/`, execute:

```powershell
flutter analyze
flutter test
```

Para mudanças de banco, também atualize a migração, `test/unit/data/database_migration_test.dart` e o dossiê técnico. Para mudanças de release, use os scripts em `tooling/` e mantenha cada saída em `builds/local/<build-id>` e `builds/github/<build-id>`.

## Dados e segurança

- Toda escrita que altera mais de uma linha deve usar `AppDatabase.transaction`.
- Não grave número completo de cartão, CVV, senhas ou chaves no banco.
- Backups criptografados usam a API de `BackupService`; nunca registre senha, conteúdo do backup ou dados financeiros nos logs.
- Imagens selecionadas pelo usuário devem ser copiadas para a pasta privada, com limite de tamanho e extensão permitida.
- Ao alterar o schema, incremente `_schemaVersion`, crie uma migração idempotente e teste a migração a partir da versão 1.

## Estilo

- Preserve o tema escuro e a adaptação para telas pequenas.
- Prefira componentes existentes e regras do domínio a lógica financeira dentro dos widgets.
- Mantenha textos voltados ao usuário em português do Brasil.
