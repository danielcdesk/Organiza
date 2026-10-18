# Planejamento financeiro mensal baseado na planilha 2026

## Intenção

Transformar o Organiza em um planejador mensal além de um livro de lançamentos. A experiência deve responder, em um único período, quanto entrou, quanto foi gasto no essencial, quanto foi gasto no não essencial, quanto sobrou, qual é a reserva de emergência desejada e quais dívidas/contas recorrentes pressionam os próximos meses.

## Fonte analisada

A planilha de referência contém uma aba mensal com:

- receitas separadas por pessoa e tipo: salário líquido, vale-alimentação, vale-refeição e rendas extras;
- despesas essenciais: moradia, condomínio, supermercado, água, luz, gás, impostos, saúde, seguro e outras essenciais;
- despesas não essenciais: academia, aplicativos/assinaturas, cartão, celular, combustível, empréstimos, educação, farmácia, veículo, animais, imprevistos, transporte, internet, lazer, streaming, alimentação fora, cuidados pessoais e tarifas;
- totais de entradas, despesas essenciais, despesas não essenciais e despesas gerais;
- sobra mensal e reserva de emergência calculada como seis vezes o custo básico.

## Decisões de produto

1. A classificação essencial/não essencial pertence à categoria, com possibilidade de override por lançamento quando uma compra específica fugir da regra da categoria. Categorias existentes sem classificação começam como “não classificada” e continuam aparecendo nos relatórios.
2. O planejamento mensal usa lançamentos pela data civil de ocorrência, sem alterar a regra já documentada para compras/faturas de cartão.
3. Fontes de renda são uma dimensão opcional de um lançamento de receita. Lançamentos antigos permanecem sem fonte e continuam somando normalmente.
4. A reserva de emergência é uma meta calculada, não um saldo disponível: alvo = meses configurados (padrão 6) × média do custo essencial dos últimos 3 meses completos. O usuário pode editar meses e excluir categorias do cálculo.
5. Dívidas são registradas separadamente de despesas comuns. Cada parcela gera um lançamento planejado na conta, mas o principal da dívida não é contado novamente como despesa quando a parcela é materializada; juros e tarifas entram como despesa.
6. Contas recorrentes representam obrigações futuras (nome, categoria, valor estimado, periodicidade, dia, conta e ativo). A previsão usa o valor estimado; a confirmação cria um lançamento normal vinculado à obrigação.
7. O primeiro corte não importa automaticamente linhas da planilha. A planilha serve de referência de domínio e categorias; importação de extratos continua sendo um fluxo separado.

## Blocos de entrega

### Bloco 1 — Planejamento mensal

Adicionar propriedades de essencialidade às categorias, fonte de receita e resumo mensal com entradas, essenciais, não essenciais, não classificadas, sobra e taxa de poupança. Incluir tela de planejamento com período selecionável e edição das classificações.

### Bloco 2 — Reserva e indicadores

Adicionar preferências locais para meses-alvo e categorias incluídas, cálculo testável da média essencial e indicadores de sobra, comprometimento da renda, investimento do mês e progresso da reserva.

### Bloco 3 — Dívidas e contas recorrentes

Adicionar tabelas e CRUD para dívidas e obrigações recorrentes, projeção de vencimentos, confirmação de parcela/conta e edição/exclusão com transação e desfazer quando aplicável.

## Não objetivos

- Não haverá sincronização, servidor, consulta bancária ou modelo de recomendação externa.
- Não haverá classificação automática irreversível nem alteração silenciosa de lançamentos históricos.
- Não haverá conversão automática da planilha em banco sem revisão do usuário.

## Restrições técnicas

- Valores em centavos inteiros.
- Datas de negócio como `yyyy-MM-dd`, sem fuso.
- Escritas multi-linha em `AppDatabase.transaction`.
- Migração idempotente testada a partir do schema 1 e novas tabelas incluídas em `_backupTables`.
- Nenhum número completo de cartão, CVV, senha ou dado financeiro em logs.
- Textos em pt-BR e visual existente preservado.
