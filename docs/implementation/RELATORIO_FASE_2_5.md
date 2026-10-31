# Relatório — Fase 2.5: tags e anexos

Data: 2026-10-30. Branch `codex/organiza-v3-fase-2-5`, baseada no branch da Fase 2.4.

## Entregas

- Schema 21 com tabelas `tags`, `transaction_tags` e `attachments`, FKs em cascata e inclusão no snapshot/backup.
- Migração incremental preserva os dados e saldo; fixtures v1, v17, v18, v19 e v20 cobrem avanço até o schema atual.
- Store com CRUD de tags, vínculo substituível por transação e preservação dos vínculos após exclusão lógica.
- Histórico aceita filtro por tag; edição permite selecionar várias tags e modal permite criar, renomear e excluir.
- Anexos privados JPG/JPEG/PNG/WEBP/GIF/PDF, nome UUID, verificação de assinatura, caminho restrito, tamanho máximo de 10 MiB e hash SHA-256 conferido na leitura da imagem.
- Backup ZIP criptografado v2 inclui anexos, contagem, tamanho e hash; archives v2 antigos sem anexos continuam aceitos.
- Interface lista imagens com prévia e PDFs por nome, MIME e tamanho; permite adicionar e remover.

## Validação local

- `flutter analyze --no-pub`: sem problemas.
- `flutter test --no-pub --coverage`: 214 testes aprovados; cobertura 74,33% (8.924/12.006 linhas).
- `flutter test integration_test -d windows --no-pub`: 2 fluxos aprovados.
- `git diff --check`: limpo.
- Testes específicos cobrem migrações/snapshot, unicidade/cascatas, assinaturas e limite dos arquivos, caminhos inválidos, backup v2 antigo e novo, hashes/contagem e restauração com anexos.

## Limites e próximos gates

CI do draft PR em Windows, Ubuntu e Android ainda é o gate remoto. Não foi testado em dispositivo Android físico. A prévia embutida é para imagens; PDFs são identificados por nome/tipo/tamanho e não têm visualizador interno.
