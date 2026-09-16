# Arquitetura

O Organiza é local-first: a interface chama `OrganizaStore`, que coordena regras do domínio e o repositório de dados. `AppDatabase` é a única camada que conhece SQL.

```text
Presentation (Flutter)
        ↓
Application (OrganizaStore)
        ↓
Domain (models + FinancialRules)
        ↓
Database (SQLite + migrações)
```

## Dados e migrações

O banco fica no diretório de suporte da aplicação, fora do repositório. `PRAGMA user_version` é a versão do schema; cada nova versão deve incluir uma migração incremental e testes que partam da versão anterior. O schema 2 adiciona `credit_cards` e `card_purchases`; o schema 3 acrescenta a instituição de cada conta e a tabela `investments`; o schema 4 adiciona categoria às transações e a tabela `budgets`; o schema 5 adiciona subcategoria e `subscriptions`; o schema 6 persiste a distribuição salarial; o schema 7 adiciona `financial_goals`; o schema 8 amplia lançamentos e investimentos; o schema 9 inclui lista de desejos; o schema 10 guarda taxa de rentabilidade informada e período opcional nas posições; o schema 11 registra o dia de rendimento informado, séries salariais, categorias de metas e preferências móveis. Nenhuma dessas migrações apaga os dados anteriores. Nunca peça ao usuário para apagar o banco.

O corte inicial usa o pacote `sqlite3` diretamente para manter o repositório compilável sem arquivos gerados. A próxima alteração de persistência deve introduzir Drift sem trocar o schema silenciosamente: primeiro criar DAOs equivalentes, migrar testes e validar um banco existente.

## Fronteiras

`BackupService`, notificações, arquivos e integração futura EditalOS devem permanecer em `services/` ou `importers/`. Nenhuma delas pode ser pré-requisito para abrir ou usar os dados locais.
