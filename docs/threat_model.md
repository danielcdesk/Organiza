# Modelo de ameaças local

## Ativos

- Banco SQLite com saldos, lançamentos, metas e preferências.
- Fotos do perfil e da lista de desejos.
- CSVs e backups exportados.
- Senha usada para abrir um backup criptografado.

## Cenários considerados

| Cenário | Proteção atual | Limite conhecido |
|---|---|---|
| Outro usuário acessa o mesmo Windows | Banco fica em `%LOCALAPPDATA%` e o acesso depende da conta do sistema | O Organiza não cifra o SQLite por padrão |
| Backup copiado para uma nuvem ou pendrive | Backup pode ser AES-256-GCM com senha e Argon2id | A senha não pode ser recuperada; exportações CSV continuam sem criptografia |
| Arquivo de backup alterado | Autenticação GCM e hash do payload fazem a restauração falhar | Não há assinatura por identidade externa |
| Imagem muito grande ou tipo inesperado | Extensões permitidas e limite de 10 MB | Não há redimensionamento/recompressão ainda |
| Falha no meio de uma série de lançamentos | Parcelamentos, salários e restauração usam transação SQLite | Outras operações de escrita simples ainda podem ser agrupadas no futuro |
| Perda ou troca de dispositivo Android | Backup automático desativado para evitar cópia sem controle | É necessário exportar e restaurar manualmente |

## Decisões de implementação

- `foreign_keys`, `busy_timeout`, WAL e `synchronous=NORMAL` são configurados na abertura persistente.
- O banco do Windows migra de `%APPDATA%` para `%LOCALAPPDATA%` quando existe uma instalação anterior.
- A restauração valida schema, colunas, chaves estrangeiras e `integrity_check` antes do commit.
- O índice único `(series_id, occurred_on)` evita duplicar uma ocorrência da mesma série na mesma data.

## Próximas avaliações

O especialista deve decidir se vale adotar SQLCipher ou outra proteção do SQLite, como guardar/recuperar a chave, e se os CSVs precisam de uma opção protegida. Essas escolhas dependem do modelo de distribuição e do risco aceito pelo produto.
