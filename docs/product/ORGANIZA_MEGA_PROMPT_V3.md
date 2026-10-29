# ORGANIZA — MEGA PROMPT V3 (EVOLUÇÃO: CONFIABILIDADE, DADOS, SEGURANÇA E USO DIÁRIO)

> Cole este arquivo inteiro no agente de código (Codex, Claude Code etc.) com o repositório `Organiza` aberto.
> Ele **complementa** `AGENTS.md` e `docs/product/ORGANIZA_MEGA_PROMPT.md` (v2.0, histórico da construção inicial).
> Em conflito: `AGENTS.md` > este arquivo > mega prompt v2.0.

---

## 0. COMO VOCÊ DEVE TRABALHAR

Você é um engenheiro sênior de Flutter/Dart e SQLite, com foco em segurança e dados financeiros. Trate este arquivo como **contrato de implementação**, não como sugestão.

### Antes de escrever qualquer código
1. Leia, nesta ordem: `AGENTS.md`, `docs/architecture.md`, `docs/financial_rules.md`, `docs/DECISIONS.md`, `docs/threat_model.md`, `docs/known_good_state.md`, `docs/testing_strategy.md`.
2. Leia `lib/database/app_database.dart` (schema 16, migrações, backup/restauração), `lib/application/organiza_store.dart`, `lib/domain/*.dart` e `lib/services/*.dart`.
3. Rode `flutter pub get`, `flutter analyze` e `flutter test` e **registre a linha de base** (quantos testes passam). Se algo já falha, pare e reporte antes de mexer em qualquer coisa.
4. **Não presuma nada que este arquivo não prove.** Onde este arquivo diz "verifique", abra o código e confirme. Se encontrar divergência entre este texto e o código, o código vence: registre a divergência em `docs/DECISIONS.md` e siga com o que o código mostra.

### Regras de execução
- Trabalhe **uma fase por vez**, na ordem (Seção 5). Só avance quando a fase atual cumprir todos os critérios de aceite, com `flutter analyze` sem problemas e `flutter test` verde.
- Mudanças pequenas e reversíveis, com commits separados por tarefa (mensagem em português, no imperativo).
- Ao final de cada fase, entregue o **Relatório de Fase** (Seção 8).
- Se uma decisão de produto for necessária e não estiver respondida na Seção 7, **pare e pergunte**. Não escolha em silêncio.
- Nunca declare algo como "funcionando" sem ter rodado. Se não rodou, escreva "não validado".

---

## 1. RESTRIÇÕES INEGOCIÁVEIS (herdadas do projeto)

1. **Local-first.** Nenhuma rede, telemetria, analytics, login remoto ou sincronização sem uma decisão de produto documentada em `docs/DECISIONS.md` **e aprovação humana explícita**. A Fase 7 é a única que pode propor isso, e só como proposta.
2. **Dinheiro = inteiro em centavos.** Nunca `double` para valores monetários. Datas de negócio não dependem de fuso do dispositivo.
3. **Toda escrita que altera mais de uma linha usa `AppDatabase.transaction`.**
4. **Nunca gravar** número completo de cartão, CVV, senhas ou chaves no banco. Nunca logar senha, conteúdo de backup ou dados financeiros.
5. **Mudança de schema** exige: incrementar `_schemaVersion`, migração **idempotente**, teste de migração a partir da versão 1 **e** da versão anterior, e atualização de `docs/technical_dossier.md`. Nunca peça ao usuário para apagar o banco.
6. **Widgets não executam SQL** nem contêm regra financeira. Regra vai para `domain/`.
7. **Textos de usuário em português do Brasil.** Preserve tema escuro/claro e a adaptação a telas pequenas.
8. **Fora de escopo:** IA/LLM dentro do produto, gamificação (XP, streak, medalhas), módulo de hábitos/hidratação, recomendação de investimento, execução de ordens.
9. **Imagens do usuário:** copiar para a pasta privada, com limite de tamanho e extensão permitida (já existe em `local_image_service.dart`; reutilize).

---

## 2. ESTADO ATUAL (VERIFICADO NO CÓDIGO)

**Stack:** Flutter, `sqlite3 ^3.5.2` direto (sem Drift), `cryptography`, `file_picker`, `path_provider`, `window_manager`. Alvos: Windows e Android. Versão `0.9.0+13`. ~20,7 mil linhas em `lib/`. Schema **16**.

**Pontos fortes a preservar:** centavos inteiros; WAL + `foreign_keys` + `busy_timeout`; migrações incrementais testadas; restauração com `integrity_check` e `foreign_key_check`; backup AES-256-GCM com Argon2id; proteção contra injeção de fórmula no CSV (`_escape` em `report_export_service.dart`); trava de instância única no Windows; documentação rica.

### Problemas confirmados (cada um vira tarefa nas fases)

| ID | Problema | Onde verificar |
|---|---|---|
| D1 | Transações guardam `category` e `subcategory` como **texto**, sem FK. Renomear categoria quebra histórico. Orçamentos e assinaturas também usam texto. | `models.dart` (`TransactionRecord`), `app_database.dart` ~linhas 309–332, 384–404 |
| D2 | `card_purchases` **não tem categoria**. Gastos no cartão não entram nos relatórios por categoria, no fluxo de caixa nem na projeção (nenhuma referência a `cardPurchases` em `reports_page.dart`, `cash_flow_summary.dart`, `balance_projection.dart`). | grep `cardPurchases` |
| D3 | **Não existe pagamento/histórico de fatura.** Só `card_installment_payments` (parcelas pagas, sem lançamento em conta). | `feature_matrix.md`, linha ~490 de `app_database.dart` |
| D4 | `restoreSnapshot` só aceita backup do **mesmo schema** (`version != schemaVersion` → erro). Um backup do schema 16 não restaura no 17. | `app_database.dart` ~linha 153 |
| D5 | O snapshot cobre só tabelas (`_backupTables`). **Fotos** (perfil e lista de desejos) ficam como caminho de arquivo e **não vão no backup**; `profile_photo_path` é caminho absoluto, que quebra ao mudar de aparelho/usuário. | `_backupTables`, `basic_pages.dart:1578` |
| D6 | O backup criptografado existe como serviço, mas a matriz de funcionalidades o marca como "não executado" e não há agendamento nem rotação. | `feature_matrix.md`, `backup_service.dart` |
| D7 | `reload()` recarrega **17 coleções inteiras** a cada mudança e `loadTransactions()` faz `SELECT *` de tudo. Sem paginação, agregação em SQL ou recarga granular. | `organiza_store.dart:143`, `app_database.dart:690` |
| D8 | Getters de preferência (`themePreference`, `profileName` etc.) consultam o banco a cada acesso. | `organiza_store.dart` ~linhas 44–60 |
| D9 | Banco **sem criptografia** (já listado no modelo de ameaças). Sem bloqueio por PIN/biometria. | `threat_model.md` |
| D10 | `OrganizaStore` (~1.300 linhas) e arquivos de UI gigantes: `dialogs.dart` 2.514, `dashboard_page.dart` 1.940, `organiza_app.dart` 1.844, `basic_pages.dart` 1.842, `reports_page.dart` 1.385. | `wc -l` |
| D11 | **Sem CI** (não há `.github/workflows`). Build por scripts PowerShell manuais em `tooling/`. | raiz do repo |
| D12 | `DateTime.now()` direto na UI, contornando o `Clock` injetado (testabilidade e consistência de "hoje"). | grep `DateTime.now()` em `lib/presentation` |
| D13 | Exportação CSV só tem `conta_id` (UUID) e `valor_centavos`; **não há importação** de nenhum formato. | `report_export_service.dart` |
| D14 | Investimentos guardam só "aplicado" e "valor atual": sem aportes/resgates/dividendos nem histórico de valor; sem gráfico de patrimônio ao longo do tempo. | `InvestmentPosition` |
| D15 | Sem lembretes/notificações de vencimentos (calendário existe, aviso não). | grep `notification` em `lib` e `pubspec.yaml` |
| D16 | Documentação defasada: README aponta APK 0.7.1; `known_good_state.md` ainda fala de 0.6.0; datas da matriz são de setembro. | docs |
| D17 | `closing_day` e `due_day` limitados a 1–28 por `CHECK`. Cartões reais podem fechar/vencer nos dias 29–31. (Baixa prioridade.) | schema `credit_cards` |
| D18 | Apenas pt-BR, com textos fixos no código; moeda única (BRL). | `organiza_app.dart:67` |

---

## 3. DECISÕES TÉCNICAS JÁ TOMADAS NESTE PLANO

Registre cada uma em `docs/DECISIONS.md` antes de implementar:

1. **Cartão: competência vs. caixa.** Relatórios por categoria usam a **data da compra** (competência). O fluxo de caixa e a projeção de saldo usam o **vencimento da fatura**. O **pagamento de fatura** é um movimento de conta que **não conta como despesa de categoria** (evita contar duas vezes). Escreva isso em `docs/financial_rules.md` com exemplos numéricos.
2. **Fatura não armazena total como fonte da verdade.** O total é derivado das compras/parcelas por `credit_card_rules.dart`. A tabela de faturas guarda período, status e pagamentos.
3. **Open Finance fica fora do núcleo.** Segundo relatos de desenvolvedores em fóruns, o acesso exige instituição regulada ou agregador pago, e conflita com local-first. O caminho realista para "trazer dados do banco" é **importação de OFX/CSV**. Confirme os custos atuais antes de qualquer proposta.
4. **Criptografia do banco:** usar SQLite3MultipleCiphers ou SQLCipher via *build hooks* do pacote `sqlite3` (a documentação do pacote descreve `hooks: user_defines: sqlite3: source: sqlite3mc`; `sqlcipher` também é opção). **Verifique a documentação da versão instalada** antes de configurar; não presuma sintaxe.
5. **Drift é opcional e isolado** (Fase 3, item 3.6). Só entra com testes de equivalência sobre bancos reais. Não misture com outras mudanças de schema.

---

## 4. PADRÕES DE MIGRAÇÃO (VALEM PARA TODAS AS FASES)

- Cada migração: `if (current < N) { BEGIN; ...; PRAGMA user_version = N; COMMIT; }`, idempotente (`IF NOT EXISTS`, checagem de coluna via `PRAGMA table_info`).
- **Antes de migrar**, copie `organiza.db` (e `-wal`/`-shm` fechados) para `organiza.db.pre-vN.bak` na mesma pasta privada; mantenha as 3 cópias mais recentes. Só apague a cópia após o app abrir e passar `integrity_check`.
- Backfill sempre dentro da transação, com contagem antes/depois no teste.
- Testes obrigatórios por migração: (a) v1 → atual; (b) v(N−1) → N com dados realistas; (c) rodar a migração **duas vezes** (idempotência); (d) `PRAGMA foreign_key_check` e `integrity_check` vazios/ok; (e) saldo consolidado idêntico antes e depois.
- Para criar fixtures: acrescente métodos `openInMemoryFromVersionNForTest()` seguindo o padrão existente, **e** gere um gerador de massa de dados (Fase 0) para testes de volume.
- Os trechos SQL abaixo são **esboços**: confirme nomes de colunas reais no código antes de usar.

---

## 5. FASES

### FASE 0 — Fundação de qualidade (começar aqui)
**Objetivo:** impedir regressão e criar instrumentos de medição.

- 0.1 **CI no GitHub Actions** (`.github/workflows/ci.yml`): `flutter pub get`, `flutter analyze`, `flutter test --coverage`, em `windows-latest` (e `ubuntu-latest` para analyze/test unitário). Cache do pub. Falha o PR se quebrar. Job separado e manual para `flutter build windows --release` e `flutter build apk` (sem expor chaves; assinatura continua local).
- 0.2 **Dependabot** semanal para `pub` e `github-actions`.
- 0.3 **Lints:** reforçar `analysis_options.yaml` (ex.: `always_declare_return_types`, `unawaited_futures`, `prefer_const_constructors`) sem quebrar o build; corrigir o que aparecer.
- 0.4 **Eliminar `DateTime.now()` na UI (D12):** tudo via `store.clock`. Teste que congela o relógio e valida o "hoje" em dashboard e lançamento.
- 0.5 **Gerador de massa de dados** (`test/support/seed_generator.dart`): cria N contas, 10 mil+ transações, séries, cartões, compras parceladas. Usado em testes de desempenho (limites definidos na Fase 3).
- 0.6 **Sincronizar docs (D16):** README (versão, links, status real), `known_good_state.md`, `feature_matrix.md` com data e resultado real dos testes.

**Aceite:** CI verde no PR; cobertura reportada; nenhuma chamada a `DateTime.now()` em `lib/presentation`; docs coerentes com o código.

---

### FASE 1 — Backup e restauração confiáveis (D4, D5, D6)
**Objetivo:** o usuário nunca perde dados ao trocar de aparelho ou atualizar o app.

- 1.1 **Novo formato de backup `.organizabak` (v2)**: um contêiner (zip) com `manifest.json` (app version, schema version, data, contagens por tabela), o banco copiado de forma consistente (`VACUUM INTO` ou API de backup do SQLite) e a pasta de imagens. Criptografar o contêiner inteiro com AES-256-GCM + Argon2id (reutilize `BackupService.encryptContent`, ajustando para bytes). Manter **leitura** do formato JSON v1 atual.
- 1.2 **Restauração entre versões:** abrir a cópia em arquivo temporário, rodar `_migrate()` até a versão atual, validar (`integrity_check`, `foreign_key_check`), mostrar **prévia** (contagens de contas, transações, cartões; data do backup; versão) e só então trocar o banco de forma atômica, mantendo `organiza.db.pre-restore.bak`.
- 1.3 **Imagens portáveis (D5):** guardar caminhos **relativos** à pasta privada do app; migração converte caminhos absolutos existentes (copiando o arquivo se ainda existir). Backup inclui as imagens; restauração as recoloca.
- 1.4 **Backup agendado e rotação:** a cada N dias (configurável) ou ao fechar o app, gerar backup local criptografado em pasta escolhida pelo usuário (no Android, via seletor de pasta do sistema). Manter os K últimos. Lembrete se o último backup tem mais de X dias. Sem rede.
- 1.5 **UI em Configurações → Backup:** exportar agora, restaurar (com confirmação e prévia), escolher pasta, ver data do último backup. Textos claros: "A senha não pode ser recuperada".
- 1.6 Atualizar `threat_model.md`, `technical_dossier.md`, `feature_matrix.md`.

**Testes obrigatórios:** backup do schema 16 restaurando num app já no schema atual (simule com migração fictícia); senha errada falha sem tocar no banco; arquivo adulterado falha; restauração interrompida (simule exceção) mantém o banco original; imagens voltam; backup v1 (JSON) ainda restaura.

**Aceite:** ciclo exportar → apagar dados → restaurar devolve saldo idêntico, imagens e preferências.

---

### FASE 2 — Modelo de dados (D1, D2, D3, D14, D17 + base para o futuro)
**Objetivo:** corrigir a fonte da verdade dos dados. Uma migração por tema, schema 17, 18, 19… em commits separados.

**2.1 Categorias com FK (schema 17)**
```sql
-- esboço; confirme colunas reais de finance_categories/finance_subcategories
ALTER TABLE transactions ADD COLUMN category_id TEXT REFERENCES finance_categories(id) ON DELETE SET NULL;
ALTER TABLE transactions ADD COLUMN subcategory_id TEXT REFERENCES finance_subcategories(id) ON DELETE SET NULL;
-- backfill por nome (case-insensitive) respeitando o tipo (receita/despesa); criar categoria "Outros" se faltar
CREATE INDEX IF NOT EXISTS idx_transactions_category_date ON transactions(category_id, occurred_on);
```
- Manter as colunas de texto durante a transição (leitura de fallback), atualizadas por um único ponto de escrita.
- **Renomear categoria propaga** (agora é só `UPDATE finance_categories`). Arquivar em vez de excluir quando há uso (`archived_at`).
- Aplicar o mesmo a `budgets`, `subscriptions` e `financial_goals` (cada um com seu `category_id`), com backfill e testes.

**2.2 Cartões completos (schema 18)**
```sql
ALTER TABLE card_purchases ADD COLUMN category_id TEXT REFERENCES finance_categories(id) ON DELETE SET NULL;
ALTER TABLE card_purchases ADD COLUMN subcategory_id TEXT REFERENCES finance_subcategories(id) ON DELETE SET NULL;

CREATE TABLE card_invoices (
  id TEXT PRIMARY KEY NOT NULL,
  card_id TEXT NOT NULL REFERENCES credit_cards(id) ON DELETE RESTRICT,
  reference_year INTEGER NOT NULL,
  reference_month INTEGER NOT NULL CHECK(reference_month BETWEEN 1 AND 12),
  closing_on TEXT NOT NULL,
  due_on TEXT NOT NULL,
  status TEXT NOT NULL CHECK(status IN ('open','closed','partially_paid','paid')),
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  UNIQUE(card_id, reference_year, reference_month)
);
CREATE TABLE card_invoice_payments (
  id TEXT PRIMARY KEY NOT NULL,
  invoice_id TEXT NOT NULL REFERENCES card_invoices(id) ON DELETE CASCADE,
  account_id TEXT NOT NULL REFERENCES accounts(id) ON DELETE RESTRICT,
  transaction_id TEXT REFERENCES transactions(id) ON DELETE SET NULL,
  amount_cents INTEGER NOT NULL CHECK(amount_cents > 0),
  paid_on TEXT NOT NULL,
  created_at TEXT NOT NULL
);
CREATE INDEX idx_card_invoice_payments_invoice ON card_invoice_payments(invoice_id);
```
- Em `domain/credit_card_rules.dart`: derivar o total da fatura, status e atraso; pagamento parcial; estorno; **fatura fechada não muda silenciosamente** quando uma compra antiga é editada (exigir confirmação).
- **Pagamento de fatura** cria uma saída na conta escolhida, marcada como tipo de sistema (`card_payment`) que **não entra como despesa de categoria** (Decisão 1). Aplicar na projeção (`balance_projection.dart`) usando o vencimento.
- Compras do cartão passam a aparecer em relatórios por categoria (competência) e na agenda/projeção (vencimento).
- Avaliar relaxar `CHECK(closing_day/due_day BETWEEN 1 AND 28)` para 1–31 com ajuste ao último dia do mês (reconstrução de tabela, com cuidado). Baixa prioridade.

**2.3 Colunas de auditoria e exclusão lógica (schema 19)**
- `updated_at TEXT` e `deleted_at TEXT NULL` em `transactions`, `accounts`, `credit_cards`, `card_purchases`, `investments`, `budgets`, `subscriptions`, `financial_goals`, `shopping_items`, `tasks`.
- Todas as consultas de leitura filtram `deleted_at IS NULL` (centralizar em views ou em um único ponto; **teste que falha se uma consulta esquecer o filtro**).
- **Desfazer exclusão** (snackbar "Desfazer" por alguns segundos) usando a exclusão lógica. Purga definitiva opcional (ex.: > 30 dias) com confirmação.
- Esse passo também prepara o app para uma eventual sincronização (Fase 7), sem ativá-la.

**2.4 Contas (schema 20)**
- `accounts.type` (`checking`, `savings`, `wallet`, `investment`, `other`), `archived_at`, `include_in_net_worth INTEGER DEFAULT 1`. Conta arquivada some das listas de lançamento, mas mantém histórico e saldo no patrimônio se marcada.
- Moeda: **não implementar multi-moeda agora**. Apenas reservar `currency TEXT NOT NULL DEFAULT 'BRL'` e documentar que valores de moedas diferentes ainda não se somam.

**2.5 Tags e anexos (schema 21)**
```sql
CREATE TABLE tags (id TEXT PRIMARY KEY NOT NULL, name TEXT NOT NULL COLLATE NOCASE UNIQUE, color_value INTEGER, created_at TEXT NOT NULL);
CREATE TABLE transaction_tags (
  transaction_id TEXT NOT NULL REFERENCES transactions(id) ON DELETE CASCADE,
  tag_id TEXT NOT NULL REFERENCES tags(id) ON DELETE CASCADE,
  PRIMARY KEY (transaction_id, tag_id)
);
CREATE TABLE attachments (
  id TEXT PRIMARY KEY NOT NULL,
  transaction_id TEXT NOT NULL REFERENCES transactions(id) ON DELETE CASCADE,
  relative_path TEXT NOT NULL,
  mime_type TEXT NOT NULL,
  size_bytes INTEGER NOT NULL CHECK(size_bytes > 0),
  sha256 TEXT NOT NULL,
  created_at TEXT NOT NULL
);
```
- Anexos copiados para a pasta privada; limite de tamanho; lista de extensões permitidas (imagem e PDF); entram no backup (Fase 1).

**2.6 Investimentos com histórico (schema 22)**
```sql
CREATE TABLE investment_movements (
  id TEXT PRIMARY KEY NOT NULL,
  investment_id TEXT NOT NULL REFERENCES investments(id) ON DELETE CASCADE,
  kind TEXT NOT NULL CHECK(kind IN ('contribution','withdrawal','dividend','fee')),
  amount_cents INTEGER NOT NULL CHECK(amount_cents > 0),
  occurred_on TEXT NOT NULL,
  account_id TEXT REFERENCES accounts(id) ON DELETE SET NULL,
  created_at TEXT NOT NULL
);
CREATE TABLE investment_valuations (
  id TEXT PRIMARY KEY NOT NULL,
  investment_id TEXT NOT NULL REFERENCES investments(id) ON DELETE CASCADE,
  valued_on TEXT NOT NULL,
  value_cents INTEGER NOT NULL CHECK(value_cents >= 0),
  UNIQUE(investment_id, valued_on)
);
```
- Migração cria uma valorização inicial a partir do "valor atual" existente e um aporte inicial igual ao "aplicado". **Nenhum valor atual pode mudar** após a migração (teste).
- Domínio: ganho = valor atual − (aportes − resgates) + dividendos; mostrar separado da taxa informada pelo usuário (regra já existente). **Sem cotações automáticas** (sem rede): atualização manual de valor gera nova valorização.
- **Patrimônio líquido ao longo do tempo:** soma de saldos de contas (que entram no patrimônio) + valorizações de investimentos − faturas em aberto − dívidas. Gráfico mensal em Relatórios.

**2.7 Dívidas e financiamentos (schema 23, opcional se a Seção 7 aprovar)**
- `debts` (nome, credor, valor original, taxa informada, parcelas) e vínculo das parcelas com a agenda. Entra no patrimônio líquido como passivo.

**2.8 Importação — colunas de apoio (schema 24; ver Fase 5)**
```sql
CREATE TABLE import_batches (
  id TEXT PRIMARY KEY NOT NULL, source_kind TEXT NOT NULL, file_name TEXT NOT NULL,
  account_id TEXT REFERENCES accounts(id), row_count INTEGER NOT NULL, imported_at TEXT NOT NULL
);
ALTER TABLE transactions ADD COLUMN import_batch_id TEXT REFERENCES import_batches(id) ON DELETE SET NULL;
ALTER TABLE transactions ADD COLUMN external_id TEXT;
CREATE UNIQUE INDEX IF NOT EXISTS idx_transactions_external ON transactions(account_id, external_id) WHERE external_id IS NOT NULL;
CREATE TABLE categorization_rules (
  id TEXT PRIMARY KEY NOT NULL, match_kind TEXT NOT NULL CHECK(match_kind IN ('contains','starts_with','regex')),
  pattern TEXT NOT NULL, category_id TEXT NOT NULL REFERENCES finance_categories(id) ON DELETE CASCADE,
  subcategory_id TEXT REFERENCES finance_subcategories(id) ON DELETE SET NULL,
  priority INTEGER NOT NULL DEFAULT 100, is_active INTEGER NOT NULL DEFAULT 1, created_at TEXT NOT NULL
);
```

**Aceite da Fase 2:** todas as migrações passam nos testes da Seção 4; saldo consolidado e totais mensais idênticos antes/depois; gastos de cartão aparecem em relatórios e projeção; renomear categoria atualiza todo o histórico; pagar fatura não duplica despesa.

---

### FASE 3 — Desempenho e arquitetura (D7, D8, D10)
**Objetivo:** o app continua fluido com 5–10 anos de histórico.

- 3.1 **Metas de desempenho** (meça com o gerador da Fase 0, 50 mil transações; registre os números reais em `docs/testing_strategy.md`): abrir a visão geral, abrir a lista de lançamentos e filtrar por mês devem ficar abaixo de um limite que você **mede antes e depois**. Não invente o limite: capture a linha de base e proponha metas.
- 3.2 **Recarga granular:** substituir `reload()` global por `reloadTransactions()`, `reloadCards()` etc., chamadas só pelo caso de uso afetado. Manter `reload()` apenas para início e restauração.
- 3.3 **Agregação em SQL:** totais do mês, ranking por categoria, evolução de 6 meses e mapa anual via `GROUP BY` com índices; a UI deixa de iterar sobre todas as transações em memória. Datas são texto ISO, então intervalos usam `occurred_on >= ? AND occurred_on < ?`.
- 3.4 **Paginação por cursor** (keyset por `occurred_on, created_at, id`) na lista de lançamentos, com os totais do filtro calculados em SQL.
- 3.5 **Índices:** `transactions(account_id, occurred_on)`, `transactions(is_settled, occurred_on)`, `transactions(category_id, occurred_on)`. Use `EXPLAIN QUERY PLAN` nos testes para provar que os índices são usados.
- 3.6 **Busca com FTS5** (tabela virtual de conteúdo externo + gatilhos de sincronização) para descrição/categoria/tags. **Verifique antes** se o SQLite empacotado inclui FTS5 (teste simples). Se não incluir, alternativa: coluna normalizada sem acento e índice.
- 3.7 **Cache de preferências (D8):** carregar `app_settings` uma vez em memória; escrita grava no banco e atualiza o cache.
- 3.8 **Dividir o `OrganizaStore`:** extrair controladores por área (contas, lançamentos, cartões, investimentos, orçamento/metas, configurações) mantendo `OrganizaStore` como fachada temporária para não quebrar a UI. Sem trocar de gerenciador de estado nesta fase, a menos que a Seção 7 aprove.
- 3.9 **Dividir arquivos gigantes** por funcionalidade (`dialogs.dart`, `dashboard_page.dart`, `organiza_app.dart`, `basic_pages.dart`, `reports_page.dart`), sem mudar comportamento. Testes de widget e goldens devem continuar iguais.
- 3.10 **Drift (opcional, só com aprovação da Seção 7):** criar DAOs equivalentes, rodar a mesma suíte contra os dois backends e contra bancos reais antes de trocar. Uma fase própria, sem outras mudanças de schema junto.

**Aceite:** números antes/depois documentados; nenhuma regressão visual (goldens); nenhum teste removido para "passar".

---

### FASE 4 — Segurança (D9)
**Objetivo:** dados protegidos em repouso e acesso controlado ao app.

- 4.1 **Criptografia do banco** (Decisão 4). Chave aleatória de 256 bits gerada no primeiro uso e guardada em armazenamento seguro do sistema (Android Keystore; Windows Credential Locker/DPAPI). Escolha o pacote **verificando suporte atual às duas plataformas**.
- 4.2 **Migração do banco existente em texto puro:** exportar para um banco cifrado novo, validar (`integrity_check` + contagens por tabela idênticas), trocar atomicamente e manter o `.bak` em texto puro **até o usuário confirmar** que o app abriu e funciona (e então oferecer apagá-lo com sobrescrita, sabendo que em SSD isso não é garantido; avise o usuário).
- 4.3 **Aviso obrigatório antes de ativar:** exigir backup criptografado recente. Se a chave se perder (reinstalação do Windows, troca de aparelho), os dados só voltam pelo backup.
- 4.4 **Bloqueio do app:** PIN (hash com Argon2id e sal próprio) e biometria/Windows Hello via pacote oficial de autenticação local (verifique suporte por plataforma). Bloqueia ao abrir, após inatividade configurável e ao voltar de segundo plano. Limitar tentativas com atraso progressivo.
- 4.5 **Privacidade da tela:** no Android, opção de impedir captura de tela e ocultar a prévia nos apps recentes; o modo "ocultar valores" já existente deve valer também na prévia.
- 4.6 **CSV protegido (decisão aberta, Seção 7):** opção de exportar CSV dentro do contêiner cifrado.
- 4.7 Atualizar `threat_model.md` (cenários novos, limites conhecidos).

**Testes:** banco cifrado não abre sem a chave; migração texto puro → cifrado preserva todas as linhas; PIN errado não abre; bloqueio dispara após o tempo configurado (relógio injetado).

---

### FASE 5 — Uso diário (o que mais pesa no dia a dia)
**Objetivo:** reduzir digitação e esquecimentos.

- 5.1 **Importação de extratos OFX e CSV (D13)** em `lib/importers/`:
  - Parser OFX tolerante (SGML 1.x e XML 2.x, codificações UTF-8/Latin-1), usando `FITID` como `external_id`.
  - CSV com assistente de mapeamento (data, descrição, valor, sinal/coluna de débito-crédito), formatos de data e número pt-BR (`1.234,56`), separador `;` ou `,`.
  - **Tela de prévia** antes de gravar: linhas novas, duplicadas (por `external_id` ou pela combinação data+valor+descrição normalizada), com categoria sugerida pelas regras. O usuário edita e confirma.
  - **Desfazer lote** pelo `import_batches`. Escrita toda em uma transação.
  - Não invente layouts de bancos específicos: implemente o formato genérico e deixe predefinições por banco só depois de validar com **arquivos reais fornecidos pelo usuário**.
  - O arquivo importado nunca sai do dispositivo; não registrar conteúdo em logs.
- 5.2 **Regras de categorização:** CRUD simples (contém / começa com / regex), prioridade, "aplicar às não categorizadas", e oferta de criar regra quando o usuário categoriza manualmente algo repetido.
- 5.3 **Conciliação:** ao importar, sugerir casar com lançamentos pendentes (mesmo valor, data próxima) para dar baixa em vez de duplicar.
- 5.4 **Pagamento de fatura na interface** (usa a Fase 2.2): tela de faturas por cartão, abertas/fechadas/pagas, histórico, pagamento total ou parcial, escolha da conta.
- 5.5 **Lembretes locais:** `NotificationService` (interface em `services/`) e um **planejador puro** em `domain/` (`NotificationPlanner.plan(hoje, pendências, faturas, assinaturas)`), testável sem plataforma. Android: notificações agendadas. Windows: o pacote de notificações locais **não oferece notificações repetidas/agendadas confiáveis**, então dispare ao abrir o app e por temporizador enquanto aberto; **diga isso na UI** em vez de prometer aviso com o app fechado. Antecedência configurável (ex.: 3 dias, 1 dia, no dia). Nada de rede.
- 5.6 **Lançamento rápido:** modelos/favoritos ("Aluguel", "Mercado"), duplicar lançamento, repetir o último, e atalhos de teclado (Windows) coerentes com os já existentes.
- 5.7 **Orçamento mais útil:** alertas em 80% e 100%, e **sobra que passa para o mês seguinte** (opcional por divisão).
- 5.8 **Relatórios:** patrimônio líquido no tempo (Fase 2.6), comparativo anual, maiores estabelecimentos/descrições, e **exportação em PDF** (resumo mensal e anual). CSV passa a ter nome da conta, valor decimal pt-BR e coluna de tags. Um resumo anual de rendimentos pode ajudar na declaração de imposto, mas deve trazer o aviso de que **não é aconselhamento fiscal**.
- 5.9 **Acessibilidade e idioma:** revisar contraste, leitores de tela e tamanhos de fonte; extrair textos para ARB (`flutter_localizations` já está no projeto), mantendo pt-BR como único idioma publicado por enquanto.

**Aceite:** importar um OFX real do usuário (fornecido por ele) sem duplicar ao importar duas vezes; categorias sugeridas por regra; notificações planejadas corretas em testes com relógio congelado; PDF gerado abre e confere com a tela.

---

### FASE 6 — Distribuição
- 6.1 **Windows:** empacotamento MSIX ou instalador (verifique opções atuais e assinatura de código; sem assinatura o SmartScreen avisará — documente).
- 6.2 **Android:** documentar o fluxo de assinatura de release e o backup da chave; avaliar assinatura gerenciada pela loja. Lembrar: trocar de chave exige reinstalar (já citado no README).
- 6.3 **Atualização:** verificação de atualização **só manual** (usuário abre a página de releases). Atualização automática exige rede → decisão da Seção 7.
- 6.4 **Release:** `tooling/` com scripts, `docs/releases/vX.Y.Z.md` com resultados reais dos testes, e versão em `pubspec.yaml` sempre coerente com README e changelog.

---

### FASE 7 — Condicional: sincronização entre dispositivos (SÓ PROPOSTA)
**Não implemente.** Escreva `docs/proposals/sync.md` com as opções e a recomendação, e **aguarde aprovação humana**. Conteúdo mínimo:

1. **Opção A — Sincronização por arquivo** (pasta que o usuário já sincroniza: OneDrive, Syncthing etc.): troca de pacotes cifrados; mescla por `updated_at` e exclusões lógicas (Fase 2.3); resolução de conflito por última escrita com log de conflitos. Sem servidor, sem rede própria do app.
2. **Opção B — Relé com criptografia ponta a ponta:** servidor que só vê dados cifrados. Exige rede, conta/identidade, custo de operação, política de privacidade e mudança no `AGENTS.md`.
3. **Open Finance:** documentar as exigências regulatórias e custos atuais de agregadores (pesquise fontes oficiais e comerciais antes), e por que **não é recomendado** frente à importação OFX/CSV.
4. Impacto em `threat_model.md`, `privacy_policy.md` e na promessa "sem telemetria".

---

## 6. DEFINIÇÃO DE PRONTO (VALE PARA CADA TAREFA)

- [ ] `flutter analyze` sem avisos; `flutter test` verde; testes de integração do Windows verdes quando a mudança toca fluxos.
- [ ] Testes novos para a regra nova **e** para o caso de erro.
- [ ] Se mexeu em schema: migração idempotente, teste a partir da v1 e da anterior, cópia `.pre-vN.bak`, dossiê atualizado.
- [ ] Nenhum dado financeiro, senha ou conteúdo de backup em logs.
- [ ] Texto de usuário em pt-BR; tema claro e escuro revisados; tela pequena revisada.
- [ ] `docs/change_log.md`, `docs/feature_matrix.md` e `docs/known_good_state.md` atualizados **com resultados reais**.
- [ ] Nada foi marcado como validado sem ter sido executado. Itens não testados em dispositivo físico dizem isso.

---

## 7. DECISÕES QUE EU (O DONO DO PRODUTO) PRECISO TOMAR — PERGUNTE ANTES DE AVANÇAR

Responda ao dono do produto, em lista numerada, **antes de iniciar a fase indicada**:

1. (Fase 2) Cartão: confirmar a regra de competência vs. caixa da Decisão 1 ou propor outra.
2. (Fase 2) Incluir dívidas/financiamentos agora (2.7) ou deixar para depois?
3. (Fase 3) Aprovar a troca para Drift (3.10)? Aprovar trocar `ChangeNotifier` por Riverpod/Bloc?
4. (Fase 4) Criptografia do banco: ligada por padrão ou opcional? Biometria obrigatória ou só PIN?
5. (Fase 4) CSV exportado deve ter opção protegida por senha?
6. (Fase 5) Quais bancos usar como predefinição de importação (preciso de arquivos reais de exemplo)?
7. (Fase 6) Atualização automática: permitir exceção de rede só para verificar versão?
8. (Fase 7) Há interesse real em sincronização? Qual opção (A ou B)?

---

## 8. FORMATO DE ENTREGA (RELATÓRIO DE FASE)

Ao concluir cada fase, responda exatamente com:

1. **Resumo** (até 10 linhas): o que mudou e por quê.
2. **Arquivos alterados/criados** (lista).
3. **Migrações**: versão, o que faz, como foi testada.
4. **Comandos executados e resultado real** (`flutter analyze`, `flutter test`, contagem de testes antes/depois, medições de desempenho quando houver).
5. **O que NÃO foi validado** (dispositivo físico, Windows real, arquivos bancários reais etc.).
6. **Riscos e pendências**.
7. **Decisões registradas** em `docs/DECISIONS.md`.
8. **Próxima fase** e perguntas da Seção 7 que ela exige.

---

## 9. BACKLOG (NÃO IMPLEMENTAR SEM PEDIDO)

Widgets de tela inicial, cotações automáticas, leitura de NFC-e por QR code, divisão de gastos entre pessoas, múltiplos perfis, multi-moeda com conversão, iOS (exige macOS e a toolchain da Apple), orçamento por envelopes completo, metas com aporte automático, assistente de importação por banco.

---

**Comece agora pela Seção 0 (leitura e linha de base) e depois pela Fase 0. Não pule fases. Se algo neste arquivo contradisser o código ou o `AGENTS.md`, pare, registre e pergunte.**