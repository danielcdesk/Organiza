# Estado conhecido como bom

## Baseline 2026-09-14 — Organiza 0.2 local integrado

Branch de publicação: `main`.

Funcionando:

- criação de contas;
- criação de receita, despesa e transferência;
- cálculo de saldo por conta e consolidado;
- persistência SQLite com schema versão 8 e migração incremental;
- criação e conclusão de tarefas;
- atalhos e navegação de desktop.
- dashboard responsivo em 1366×768 com saldo consolidado, resumo mensal e menor repetição visual;
- tema escuro midnight-finance refinado, inspirado na precisão e simplicidade da Apple, e tema claro equivalente;
- busca local por contas, transações, cartões e tarefas;
- cadastro de cartão com bandeira, últimos quatro dígitos, limite, fechamento e vencimento;
- registro de compras no cartão;
- cálculo do ciclo atual, fatura em aberto, limite disponível e percentual usado;
- formatação monetária brasileira com separadores de milhar;
- migração incremental do schema 1 para o schema 8;
- seleção de instituição visual para contas, incluindo Nubank, Inter, Caixa, Itaú, Banco do Brasil, Bradesco, Santander e banco genérico;
- investimentos manuais com posição, saldo atual, rentabilidade, alocação e detalhes de renda fixa;
- categorias e subcategorias persistidas e personalizáveis;
- lançamentos únicos, recorrentes e parcelados, com estado pago/pendente;
- relatórios por período com evolução, comparação, ranking de gastos e exportação CSV local;
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
- ícone próprio no executável e na navegação;

Testes:

- `flutter analyze`: sem problemas;
- `flutter test`: 20 testes aprovados;
- `flutter test integration_test -d windows`: 1 fluxo aprovado em 1366×768 por Dashboard, Contas, Investimentos, Orçamentos, Relatórios, Cartões, Assinaturas, Planejamento e Metas;
- `flutter build windows --release`: concluído;
- capturas do dashboard e de Cartões revisadas visualmente.

Contrato de regressão:

- transferências não podem alterar o patrimônio consolidado;
- valores financeiros devem continuar em centavos inteiros;
- nenhum dado pessoal pode sair do computador;
- não remover a validação de origem/destino em transferências.
- o schema 1 deve migrar para o schema 8 sem excluir contas, transações ou tarefas;
- lançamentos pendentes não podem alterar saldo, totais realizados ou orçamento consumido;
- o parcelamento deve preservar exatamente o total digitado, inclusive quando houver resto em centavos;
- cartão nunca deve armazenar número completo, CVV ou senha;
- fatura atual deve incluir a parcela correspondente de cada compra ativa no ciclo;
- dashboard e Cartões não podem apresentar overflow em 1366×768.

Limitações conhecidas:

- pagamento, fechamento definitivo e histórico de faturas entram na próxima etapa;
- importação, edição e arquivamento de cartões ainda não foram implementados.
- investimentos não possuem cotação em tempo real, integração com corretoras ou execução de ordens.
