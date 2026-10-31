# Estado conhecido como bom

## Fase 2.3 — validação local (30/10/2026)

Branch `codex/organiza-v3-fase-2-3`, sobre `codex/organiza-v3-fase-2-2`, schema 19. `flutter analyze --no-pub` sem problemas; `flutter test --no-pub --coverage` com 194 testes aprovados e 8.374/11.387 linhas (73,54%); integração Windows com 2 fluxos aprovada. Revisão independente sem achados críticos/importantes. PR draft e CI remoto ainda pendentes. Migração em banco real e execução em Android físico não foram validadas; ver [relatório da Fase 2.3](implementation/RELATORIO_FASE_2_3.md).

## Linha de base V3 — 29/10/2026

Validação local após a Fase 0: análise sem problemas com lints reforçados, 116 testes Flutter aprovados, cobertura de linhas 67,10% (6.282/9.362) e 2 fluxos de integração Windows aprovados. Sem alteração do schema. CI remoto e Android físico não são considerados aprovados por esses resultados. [Relatório de Fase 0](implementation/RELATORIO_FASE_0.md).

Fonte original 0.9.0+13, schema 16. `flutter pub get` aprovado, `flutter analyze` sem problemas e `flutter test --reporter expanded` com **108 testes aprovados** em Windows usando Flutter 3.47.7/Dart 3.13.5. Esta contagem substitui contagens históricas para a linha de base atual; não declara novos recursos implementados nem novos pacotes publicados.

Execução por fases: [progresso V3](implementation/PROGRESSO_V3.md).

## Código 0.9.0+13 — atualização 2.1 (14/10/2026)

- Análise estática sem problemas; 95 testes Flutter e 2 fluxos de integração Windows aprovados.
- Builds Windows release e Android debug concluídos. O APK de debug não é uma atualização instalável sobre o APK público assinado.
- SQLite permanece no schema 16. Preferências usam `app_settings`; parcelas pagas dos cartões ficam em `card_installment_payments`, preservando registros anteriores pela migração incremental.
- A instalação em dispositivos físicos, a assinatura Android de release e a publicação de binários 0.9.0 ainda não foram verificadas.

Detalhes: [notas 0.9.0](releases/v0.9.0.md).

## Estado verificado — build 15 (28/09/2026)

- `flutter analyze` sem problemas, `flutter test` com 45 testes aprovados e os dois fluxos de integração Windows aprovados.
- AAB gerado com `targetSdk 36`; o APK não declara `android.permission.INTERNET` e o manifesto usa `android:allowBackup="false"`.
- Artefatos disponíveis em `builds/local/v0.7.1+10-build-15-technical-hardening/` e `builds/github/v0.7.1+10-build-15-technical-hardening/`.

## 2026-09-18 — Organiza 0.7.1

- Planejamento e Orçamento têm um único ponto de entrada, Organização, tanto na barra lateral desktop quanto no menu móvel.
- Resultados de busca e atalhos rápidos usam a área unificada; um atalho antigo de Orçamento é convertido automaticamente e sem duplicar os demais atalhos.
- `flutter analyze --no-pub`, 41 testes Flutter e dois fluxos de integração Windows foram aprovados.
- Distribuição conferida: ZIP Windows com executável e DLLs necessárias (SHA-256 `3EE3979835580CFE15392A26980F5880A37168E8F56EEC8B748D3761FDC9B650`) e APK 0.7.1+10 com assinatura APK v2 válida (SHA-256 `FE217D8BCCAA5EE0A107EF461765A8ED2772EE06EDC077BC7F238808008CDBF7`).

Pacotes e verificações de distribuição: [notas 0.7.1](releases/v0.7.1.md).

## 2026-09-17 — Organiza 0.7.0

- Análise estática sem problemas e 41 testes Flutter aprovados.
- Dois fluxos integrados Windows aprovados em 1366×768 e 390×844; capturas reais revisadas para dashboard claro/escuro, contas, histórico e histórico móvel.
- Previsão exclui transferências e registros confirmados; inclui atrasos e limita o horizonte ao fim do mês.
- Confirmação/desfazer e edição individual preservam a coerência do saldo; edição de transferência não altera o total consolidado.
- Tema e ocultação persistem em app_settings. Schema 11 mantido, sem migração destrutiva.
- Componentes Flutter localizados para pt-BR. Layout móvel validado em testes; instalação em Android físico ainda não verificada.
- Pacotes de distribuição conferidos: ZIP Windows com executável e DLLs necessárias (SHA-256 `7456EDEB38F8B66B68B28627456ECDF9A866EBA8561F416A07F635E4E4FDBA57`) e APK 0.7.0+9 assinado por APK Signature Scheme v2 (SHA-256 `58118431D6874A19355E410C50BC4E53731F7F1CF3ECC44C344414247473792A`).

Pacotes e verificações de distribuição: [notas 0.7.0](releases/v0.7.0.md).

## 2026-09-17 — Organiza 0.6.1

Branch de publicação: `main`. Fontes locais analisadas e testadas antes do release.

- Tema compartilhado revisado com superfícies quentes, contraste de leitura, acento terracota e componentes de borda/raio consistentes.
- Sidebar refinada com acabamento escuro, perfil integrado e seleção ativa mais clara; cabeçalhos e navegação mobile receberam transições mais suaves.

Verificações: `flutter analyze --no-pub` sem problemas; `flutter test --no-pub` concluído; `flutter test integration_test -d windows --no-pub` aprovado; build Windows release concluído. O pacote `Organiza-Windows-0.6.1.zip` foi inspecionado quanto a executável, DLLs e assets e tem SHA-256 `4D849A6CF7E96499D14F4CBB5F6BA4F1FAC9E4887F6C937FAEB273E9F9F3E7FC`. A instalação em Android físico ainda não foi verificada.

Limite de distribuição: a compilação Android 0.6.1 não recebeu assinatura porque a chave privada não estava configurada nesta sessão. O APK assinado mais recente permanece em 0.6.0; nenhum APK não assinado foi preparado para release.

## 2026-09-16 — Organiza 0.6.0

Fontes locais analisadas e testadas antes do release.

- Schema SQLite 11 migra a base histórica sem apagar contas, movimentações, metas ou investimentos.
- Planejamento usa somente a categoria Salário; séries salariais geram uma ocorrência pendente apenas no dia devido e podem ser canceladas sem apagar meses anteriores.
- Planejamento e Orçamento compartilham uma tela; categorias de despesa e de meta podem ser criadas pelo usuário.
- Saldo atual de contas pode ser ajustado sem excluir movimentações; assinaturas podem ser editadas, pausadas e reativadas.
- Investimentos separam valor aplicado, valor atual, taxa informada e dia de crédito informado, sem projeção ou crédito automático.
- Dashboard inclui calendário de vencimentos; Relatórios incluem pizza interativa de despesas e seleção de mês.
- Celular tem menu agrupado, ação central de nova transação e quatro atalhos configuráveis na barra inferior.

Verificações: `flutter analyze --no-pub` sem problemas; `flutter test --no-pub` com 33 testes aprovados; `flutter test integration_test -d windows --no-pub` com 2 fluxos aprovados; build Windows release e APK Android release concluídos. O APK declara `versionName 0.6.0`, `versionCode 7` e assinatura v2 válida. O pacote Windows foi inspecionado quanto a executável, DLLs e assets. As capturas em `docs/screenshots/` foram atualizadas a partir dos testes integrados. A instalação em Android físico ainda não foi verificada.

Limites: não há sincronização entre PC e celular, integração bancária, cotação automática nem pagamento de fatura. O rendimento informado não altera o saldo. O salário previsto não altera o caixa até a confirmação da movimentação.

## Histórico anterior

## Baseline 2026-09-15 — Organiza 0.4 local integrado

Branch de publicação: `main`.

Funcionando:

- criação de contas;
- criação de receita, despesa e transferência;
- cálculo de saldo por conta e consolidado;
- persistência SQLite com schema versão 9 e migração incremental;
- criação e conclusão de tarefas;
- atalhos e navegação de desktop.
- dashboard responsivo em 1366×768 com saldo consolidado, resumo mensal e menor repetição visual;
- tema escuro midnight-finance refinado, inspirado na precisão e simplicidade da Apple, e tema claro equivalente;
- busca local por contas, transações, cartões e tarefas;
- cadastro de cartão com bandeira, últimos quatro dígitos, limite, fechamento e vencimento;
- registro de compras no cartão;
- cálculo do ciclo atual, fatura em aberto, limite disponível e percentual usado;
- formatação monetária brasileira com separadores de milhar;
- migração incremental do schema 1 para o schema 9;
- seleção de instituição visual para contas, incluindo Nubank, Inter, Caixa, Itaú, Banco do Brasil, Bradesco, Santander e banco genérico;
- investimentos manuais com posição, saldo atual, rentabilidade, alocação e detalhes de renda fixa;
- categorias e subcategorias persistidas e personalizáveis;
- lançamentos únicos, recorrentes e parcelados, com estado pago/pendente;
- relatórios por período com evolução, comparação, ranking de gastos e exportação CSV local;
- relatórios mensais com navegação anterior/próximo, escolha direta de mês e ano, comparação com o mês anterior e alternância entre realizado e previsto;
- exportação CSV limitada ao período e modo selecionados, com codificação compatível com Excel no Windows;
- orçamentos mensais por categoria com cálculo de consumo;
- assinaturas recorrentes com valor, dia e categoria;
- planejamento dinâmico com salário identificado pelas receitas e distribuição ajustável;
- relatórios com gastos/receitas por categoria e roadmap de calendário;
- transições de navegação, progresso animado e controle de tela cheia (F11/botão no topo);
- dashboard integrado com orçamento, assinaturas e taxa de economia;
- busca e filtros de movimentações, com exclusão confirmada;
- exclusão de orçamento e assinatura com confirmação;
- distribuição salarial persistida e balanceada em 100%;
- data e subcategoria de lançamentos persistidas corretamente;
- parcelas distribuídas por fatura e saldo parcelado considerado no limite;
- mapa anual de gastos com todos os dias do ano;
- metas financeiras com aportes e conclusão;
- exclusão de tarefas com confirmação no Planejamento e no Dashboard;
- lista de desejos/compras local com preço estimado, quantidade, prioridade, baixa e exclusão, sem alterar o saldo;
- ícone próprio no executável e na navegação;

Testes:

- `flutter analyze`: sem problemas;
- `flutter test`: 22 testes aprovados;
- `flutter test integration_test -d windows`: 1 fluxo aprovado em 1366×768 por Dashboard, Contas, Investimentos, Orçamentos, Relatórios, Cartões, Assinaturas, Planejamento e Metas;
- `flutter build windows --release`: concluído;
- capturas do dashboard e de Cartões revisadas visualmente.

Contrato de regressão:

- transferências não podem alterar o patrimônio consolidado;
- valores financeiros devem continuar em centavos inteiros;
- nenhum dado pessoal pode sair do computador;
- não remover a validação de origem/destino em transferências.
- o schema 1 deve migrar para o schema 9 sem excluir contas, transações ou tarefas;
- lançamentos pendentes não podem alterar saldo, totais realizados ou orçamento consumido;
- o parcelamento deve preservar exatamente o total digitado, inclusive quando houver resto em centavos;
- cartão nunca deve armazenar número completo, CVV ou senha;
- fatura atual deve incluir a parcela correspondente de cada compra ativa no ciclo;
- dashboard e Cartões não podem apresentar overflow em 1366×768.

Limitações conhecidas:

- pagamento, fechamento definitivo e histórico de faturas entram na próxima etapa;
- importação, edição e arquivamento de cartões ainda não foram implementados.
- investimentos não possuem cotação em tempo real, integração com corretoras ou execução de ordens.
