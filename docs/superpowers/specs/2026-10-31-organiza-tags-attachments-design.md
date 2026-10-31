# Design: Tags e anexos locais por lançamento

## Intent

Implementar a Fase 2.5 do ORGANIZA Mega Prompt V3: categorizar lançamentos existentes com tags reutilizáveis e associar comprovantes locais em imagem ou PDF. Os dados continuam privados e disponíveis offline; metadados e arquivos devem sobreviver ao backup/restauração.

## Goals

- Migrar o SQLite para schema 21 com `tags`, `transaction_tags` e `attachments`, constraints e FKs definidos no V3.
- Criar, renomear e excluir tags; associar/desassociar várias tags de um lançamento sem duplicar vínculos.
- Copiar anexos suportados para uma pasta privada, persistir caminho relativo, MIME, tamanho, SHA-256 e data.
- Limitar cada arquivo a 10 MiB e permitir somente JPEG, PNG, WebP, GIF e PDF, conferindo assinatura do conteúdo.
- Mostrar e remover anexos, preservar vínculos em exclusão lógica/restauração, exportar e restaurar mídia cifrada junto ao backup.
- Manter backups v2 anteriores compatíveis, tratando ausência de anexos como coleção vazia.

## Non-goals

- Sincronização, armazenamento remoto, OCR, alteração automática de categoria, anexar a cartões/contas, visualização avançada de PDF, ou exportação fora do backup atual.
- Permitir extensões arbitrárias ou gravação do caminho escolhido pelo usuário no banco.

## Constraints

- `tags.name` é único sem diferenciar maiúsculas/minúsculas; tag removida perde seus vínculos por FK cascade.
- `transaction_tags` e `attachments` têm FK para lançamento com `ON DELETE CASCADE`; exclusão lógica de lançamento não remove anexos ou tags.
- Referências usam `attachments/<UUID>.<ext>` com caminho relativo validado. Os bytes ficam sob o diretório privado do Organiza.
- Formatos: `.jpg`, `.jpeg`, `.png`, `.webp`, `.gif`, `.pdf`; MIME detectado da assinatura, não confiado da extensão ou picker.
- Máximo 10 MiB por anexo; o limite agregado do backup permanece o atual. Arquivos de anexos devem ter seu próprio diretório ZIP `attachments/`.
- O backup v2 existente deve continuar aceitando manifests sem `attachmentCount`; novos manifests informam contagens de imagens e anexos separadamente.
- Tags ficam acessíveis pelo editor de lançamento. Anexos são gerenciados por ação contextual no lançamento. Nenhum dado cru de arquivo entra no SQLite.

## Approaches considered

1. **Tags em texto ou JSON dentro de `transactions`:** simples de consultar na tela, mas duplica nomes, não garante unicidade/renomeação global nem integridade referencial. Rejeitada por conflitar com schema 21 e crescer dívida de dados.
2. **Tabelas relacionais para tags e metadados de anexos, arquivos em pasta privada:** usa FK e UNIQUE existentes no SQLite, permite CRUD e preserva arquivos grandes fora do banco; exige estender a lista de backup e a validação dos paths. **Escolhida**, pois corresponde ao contrato V3 e mantém backup local cifrado.
3. **Conteúdo dos anexos como BLOB no SQLite:** torna snapshot autocontido, mas aumenta banco, custo de cópias e restauração para arquivos que já são aceitos no sistema de backup como arquivos privados. Rejeitada.

## Proposed behavior

- Schema 21 cria as três tabelas exatamente com colunas, PK/UNIQUE/FK/CHECK do prompt. Tables são incluídas na allowlist de snapshot e em validação estrita.
- `tags` carregam metadados e cores. O editor pode selecionar várias tags; ação de criar tag permite adicionar sem sair do fluxo. Um gerenciador de tags permite renomear, mudar cor e excluir.
- A linha de lançamento oferece uma ação “Anexos”; o painel lista nome, tipo e tamanho, permite escolher arquivo, adicioná-lo/removê-lo e abrir imagens locais. PDF é identificado e preservado com seu tipo; visualização PDF nativa não é requisito desta fase.
- Serviço de anexos escolhe arquivo, valida extensão, tamanho e assinatura, copia por fluxo para arquivo temporário na pasta privada, calcula SHA-256, renomeia para UUID e devolve metadados; falhas limpam o temporário. Caminhos existentes são validados antes de abrir/remover.
- Backups v2 acrescentam arquivos em `attachments/` e contagem no manifesto. Restore valida hash/tamanho/path e instala arquivos antes de trocar o banco; conflito com bytes diferentes cancela a restauração sem sobrescrever o arquivo local.
- Migrações 1→21 e 20→21 validam integridade, counts existentes, leitura dos defaults e backup pré-migração.

## Open implementation choices

- Onde inserir “gerenciar tags” para caber no fluxo existente: ação no editor/finanças com dialog modal.
- UX de filtros por tag será acrescentada à busca/filtros da lista de lançamentos se couber no escopo atual, sem carregar arquivo ou conteúdo binário na lista.
- Remover anexo exclui primeiro o vínculo no banco e depois tenta limpar o arquivo; falha de limpeza deixa apenas arquivo órfão privado, recuperável por limpeza posterior, nunca metadado apontando para arquivo que já foi apagado.
