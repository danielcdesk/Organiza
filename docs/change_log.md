# Registro de mudanças

## 2026-09-17 — Organiza 0.6.1, acabamento editorial e navegação refinada

- Tema claro passou a usar uma base mais quente e suave, com contraste pensado para leitura financeira prolongada.
- A cor de ação foi consolidada em terracota discreto; cards, campos, diálogos, botões e navegação receberam cantos e sombras mais consistentes.
- A sidebar escura agora usa um acabamento mais sofisticado, melhor contraste de perfil e seleção ativa mais clara.
- Cabeçalhos ganharam contexto visual de período e o app aplica transições de entrada e troca de página também no fluxo mobile.
- Pacote Windows 0.6.1 gerado e inspecionado. O Android mantém o APK assinado 0.6.0 até que a chave privada de assinatura esteja disponível para assinar a atualização.

## 2026-09-16 — Organiza 0.6.0, planejamento integrado e vencimentos

- Planejamento considera apenas entradas classificadas como Salário e reúne a visão de orçamento, com mais categorias padrão e criação de categorias no próprio limite.
- Salário recorrente ganhou série persistida: a competência é criada só no dia devido, nasce pendente e pode ser cancelada sem apagar o histórico. Descrição de transação passou a ser opcional; salário não apresenta parcelas ou quantidade de meses.
- Contas permitem ajustar o saldo atual sem remover lançamentos anteriores.
- Investimentos permitem informar taxa, valor atual e dia mensal de crédito, mantendo rendimento esperado separado do resultado efetivo.
- Dashboard ganhou calendário mensal de contas lançadas, assinaturas ativas e vencimentos de cartão.
- Assinaturas podem ser editadas, pausadas, reativadas e exibem a próxima cobrança; o painel de roadmap foi removido.
- Relatórios ganharam pizza interativa para despesas por categoria; metas receberam categorias personalizáveis.
- No celular, o menu lateral foi agrupado como no desktop, a barra inferior ganhou ação central de nova transação e quatro atalhos configuráveis em Configurações.
- Schema local 11, com migração incremental e regressões de salário, saldo, assinaturas, preferências móveis e categorias de metas.

## 2026-09-15 — Organiza 0.5.1, rentabilidade manual e atualização de investimentos

- Posições de investimento agora aceitam taxa informada em porcentagem ao mês ou ao ano, incluindo poupança, sem presumir retorno automático.
- Valor atual e total aplicado são campos explícitos; posições podem ser editadas mantendo identidade e data de criação.
- A carteira separa taxa informada de variação acumulada simples, calculada pelo valor atual menos o total aplicado.
- O schema local passou à versão 10 com migração incremental; investimentos existentes ficam com a taxa opcional vazia, sem perda de valores.
- Testes cobrem parsing decimal da taxa, persistência/migração, edição, cálculos e diálogo mobile.

## 2026-09-15 — Organiza 0.4, tarefas e lista de compras

- Tarefas podem ser excluídas pelo Planejamento ou pelo Dashboard, sempre com confirmação.
- Criada a área Lista de desejos na navegação lateral, com cadastro de item, quantidade, preço unitário estimado opcional, prioridade e estado comprado.
- A lista mostra total estimado dos itens pendentes, filtros por estado e exclusão confirmada.
- Itens da lista não afetam o saldo, orçamentos ou relatórios; após a compra, o usuário registra a despesa real em Finanças.
- O schema local passou para a versão 9, preservando os dados anteriores; novas regressões cobrem exclusão de tarefas, persistência da lista e isolamento do saldo.

## 2026-09-14 — Organiza 0.3, Relatórios mensais

- Relatórios passaram a abrir no mês atual e permitem navegar por setas ou selecionar diretamente qualquer mês entre 2000 e 2100.
- Cards de entradas, saídas e resultado representam apenas o mês escolhido e mostram a variação em relação ao mês anterior.
- O usuário pode alternar entre visão realizada, que considera somente valores pagos/recebidos, e visão prevista, que inclui pendências.
- Evolução de 3, 6 ou 12 meses termina no período selecionado; ranking e gráficos por categoria respeitam o mesmo contexto.
- O mapa anual acompanha o ano escolhido e diferencia a leitura realizada da previsão com assinaturas.
- A exportação CSV agora contém somente o mês e modo ativos, inclui categoria, subcategoria, status e forma do lançamento e usa UTF-8 compatível com Excel.

## 2026-09-14 — Organiza 0.2, lançamentos planejados e carteira consolidada

- Contas e seletores de transação passaram a usar os ícones locais fornecidos para Nubank, Inter, Caixa, Itaú, Banco do Brasil, Bradesco e Santander.
- Categorias e subcategorias agora são entidades persistidas; o usuário pode criá-las sem sair do formulário e reutilizá-las em orçamentos e assinaturas.
- Alimentação ganhou Mercado, Restaurantes, Delivery, Padaria, Açougue, Feira, Bar e bebidas e Cafeterias.
- Lançamentos podem ser únicos, recorrentes ou parcelados. Parcelas preservam exatamente o total informado e ocorrências futuras nascem pendentes.
- Saldo, totais mensais e consumo de orçamento consideram somente lançamentos efetivados; o histórico permite alternar pago/pendente.
- Investimentos ganharam carteira consolidada, gráfico animado de alocação, exclusão de posições e painel de renda fixa por tipo, emissor e vencimento.
- O schema local passou para a versão 8, com migração incremental e novos testes de regressão.

## 2026-09-11 — Identidade final, mapa anual e Metas

- Tema claro ganhou contraste mais preciso, superfícies com profundidade sutil e componentes mais legíveis.
- Ícones de instituições receberam formas, cores e acabamentos próprios sem armazenar nem depender de imagens externas.
- Cartão de crédito ganhou composição premium, chip detalhado e identificação de bandeira; parcelas agora entram na fatura correta e reservam apenas o saldo ainda devido no limite.
- Relatórios receberam gráficos de linha e barras animados e um mapa anual com todos os dias do ano, despesas registradas e cobranças recorrentes.
- Metas financeiras passaram a aceitar objetivo, valor inicial, prazo opcional, tipo visual, aportes, conclusão e exclusão.
- Lançamentos agora persistem corretamente subcategoria e data escolhida; receitas ganharam categorias específicas.
- O schema local passou para a versão 7 e o executável recebeu uma identidade visual própria.

## 2026-09-11 — Organiza 1.1, centro financeiro integrado

- Dashboard passou a conectar orçamento, assinaturas, economia, contas e movimentações no mesmo contexto.
- Movimentações ganharam busca, filtros por tipo e exclusão com confirmação.
- Orçamentos e assinaturas ganharam exclusão segura sem apagar lançamentos históricos.
- Planejamento salarial agora mantém 100% da renda distribuída e persiste a preferência no schema 6.
- A suíte ganhou regressões para proteção de contas e persistência da distribuição salarial.

## 2026-09-11 — Fluxo financeiro, assinaturas e planejamento

- Histórico de Movimentações ganhou resumo de entradas, saídas e resultado do mês.
- Contas podem ser adicionadas e excluídas com confirmação; contas com lançamentos ficam protegidas.
- Assinaturas recorrentes passaram a ter cadastro local por valor, dia e categoria, com roadmap de cobranças.
- Relatórios ganharam gastos e receitas por categoria e calendário de gastos para as próximas semanas.
- Categorias foram ampliadas com subcategorias e o Planejamento passou a exibir e distribuir o salário identificado pelas receitas.

## 2026-09-10 — baseline inicial

**Objetivo:** criar o repositório inicial do Organiza para Windows, local e offline.

**Arquivos modificados:** estrutura Flutter, domínio financeiro, SQLite, repositório local, interface desktop, backup JSON, testes e documentação.

**Comportamento anterior:** não existia projeto neste diretório.

**Comportamento novo:** contas, lançamentos, transferências e tarefas persistem em SQLite; dashboard e atalhos foram incluídos.

**Testes adicionados/alterados:** `test/financial_rules_test.dart` e plano de fluxo em `integration_test/first_use_flow_test.dart`.

**Riscos de regressão:** toolchain não disponível para validar compilação; módulos de cartão, orçamento, investimento, metas, hidratação e relatórios ainda não existem.

**Resultado final:** fonte preparada para `flutter pub get`, análise, testes e build em máquina Windows com Flutter instalado.

## 2026-09-10 — UI/UX financeira e início de Cartões

**Objetivo:** aproximar a interface de produtos financeiros SaaS sóbrios e iniciar o módulo de cartões com persistência real.

**Arquivos modificados:** tema, shell, dashboard, páginas básicas, diálogos, domínio, banco, repositório, store, testes, README e documentação técnica.

**Comportamento anterior:** dashboard básico, Cartões sem conteúdo e busca sem resultados.

**Comportamento novo:** tema midnight-finance, dashboard mais denso, busca agrupada, cadastro de cartões, compras, ciclo atual, fatura aberta e limite disponível. O schema passou de 1 para 2 por migração incremental.

**Testes adicionados/alterados:** regras de cartão, migração 1 → 2 e fluxo Windows em 1366×768 com captura visual.

**Erros encontrados:** flex em altura ilimitada, overflow do resumo de cartão e captura nativa indisponível no Windows; todos diagnosticados, corrigidos e registrados.

**Riscos de regressão:** futura distribuição de parcelas e pagamento de fatura devem preservar o cálculo do ciclo e a migração dos dados existentes.

**Resultado final:** análise limpa, 9 testes unitários/widget, 1 integração Windows e build release aprovados.

## 2026-09-10 — refinamento SaaS premium

**Objetivo:** tornar a experiência mais moderna e próxima da precisão visual de produtos Apple, preservando a identidade financeira e local-first do Organiza.

**Arquivos modificados:** tema, shell principal, sidebar, topbar, componentes compartilhados, dashboard e página de Cartões.

**Comportamento anterior:** superfícies ocupavam toda a janela, os controles tinham aparência mais utilitária e os painéis usavam cantos menores.

**Comportamento novo:** janela com superfícies flutuantes, bordas de 20–24 px, contraste mais controlado, busca integrada, navegação com estado local visível e cartões com profundidade sutil. Não foram adicionados botões decorativos ou ações sem funcionamento.

**Testes adicionados/alterados:** o mesmo fluxo de integração foi reutilizado como contrato visual em 1366×768.

**Erro encontrado:** o aumento do espaçamento interno causou overflow de 2 px no resumo do cartão; a altura responsiva do bloco foi corrigida antes da aprovação.

**Riscos de regressão:** alterações futuras no espaçamento do painel de ciclo devem continuar sendo verificadas na resolução mínima testada.

**Resultado final:** análise limpa, 9 testes unitários/widget e 1 integração Windows aprovados; capturas revisadas visualmente e build release regenerado.

## 2026-09-10 — redução de ruído visual

**Objetivo:** remover padrões genéricos de dashboards gerados e dar ao Organiza uma hierarquia mais específica, contida e funcional.

**Arquivos modificados:** tema, navegação, componentes compartilhados, dashboard, Cartões, formatação monetária e testes de interface.

**Comportamento anterior:** quatro métricas repetiam o mesmo card, o fluxo mensal duplicava informações, chips e caixas internas adicionavam contornos, e o lime aparecia em elementos secundários.

**Comportamento novo:** saldo e movimento mensal têm composições próprias; informações repetidas foram removidas; o lime ficou reservado à ação principal e ao estado ativo; abas de cartões usam sublinhado; cartão físico respeita proporção realista; valores em BRL recebem separador de milhar.

**Testes adicionados/alterados:** cobertura de formatação para `R$ 1.234.567,89` e atualização das asserções do fluxo visual.

**Riscos de regressão:** manter a proporção do cartão e verificar textos financeiros longos quando os valores crescerem.

**Resultado final:** análise, testes e fluxo integrado aprovados em 1366×768, com revisão das duas capturas principais.

## 2026-09-11 — bancos, investimentos e relatórios

**Objetivo:** identificar visualmente as contas, ativar a carteira de investimentos e aplicar a atualização de design por blocos: sidebar escura, dashboard claro e análise visual útil.

**Arquivos modificados:** domínio, migração SQLite, repositório, store, diálogos, shell, páginas de investimentos e relatórios, exportação CSV, testes, tema e documentação.

**Comportamento anterior:** contas usavam um único ícone genérico; Investimentos e Relatórios eram áreas planejadas sem persistência ou interação.

**Comportamento novo:** cada conta pode selecionar banco genérico, Nubank, Inter, Caixa, Itaú, Bradesco ou Santander; investimentos locais calculam patrimônio, resultado, rentabilidade e alocação; Relatórios filtram 3, 6 ou 12 meses, mostram evolução, comparação e ranking, e exportam transações em CSV local.

**Migração:** o schema 3 adiciona `institution` a contas e cria `investments`, preservando dados dos schemas 1 e 2.

**Erros encontrados:** o gráfico de barras de Relatórios recebeu `Expanded` sem altura definida; foi corrigido com área de gráfico limitada e documentado em ERR-005.

**Resultado final:** análise limpa, 11 testes unitários/widget e fluxo integrado Windows aprovado em 1366×768 pelas cinco áreas financeiras principais.
## 2026-09-11 — Animações, tela cheia e início de Orçamentos

- Adicionado `window_manager` com janela inicial confortável, controle de tela cheia no topo e atalho F11.
- Navegação entre módulos ganhou transição suave e barras de progresso com entrada animada.
- Orçamentos mensais por categoria persistidos no schema 4; transações agora registram categoria e o consumo é calculado localmente.
- Criada tela de Orçamentos com resumo de limite/utilizado/disponível, progresso por categoria e estado vazio orientado à ação.
- Integração Windows passou a capturar também o módulo de Orçamentos.
