# Estado conhecido como bom

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
