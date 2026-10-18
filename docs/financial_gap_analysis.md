# Análise da planilha 2026 e do Organiza

A planilha fornecida reúne receitas por pessoa e fonte, despesas separadas
entre essenciais e não essenciais, totais mensais, sobra e uma reserva de
emergência equivalente a seis meses do custo básico. O Organiza já tinha
contas, lançamentos, cartões, orçamentos, assinaturas, investimentos, metas,
relatórios e previsão, mas faltava reunir essas informações num planejamento
mensal com essencialidade explícita.

## Entregue nesta evolução

| Necessidade da planilha | Solução no app |
|---|---|
| Receitas por tipo/fonte | Fonte opcional em cada receita e total mensal; dados antigos aparecem como “Sem fonte”. |
| Despesas essenciais e não essenciais | Categoria classificável e ajuste por lançamento; antigas permanecem como “Não classificada”. |
| Entradas, gastos, sobra e percentual | Visão mensal em Organização, com seleção de mês e ocultação de valores. |
| Reserva de seis meses | Meta configurável pela média dos três meses civis completos anteriores; saldo reservado é informado manualmente. |
| Empréstimos e parcelas | Dívida com principal, juros mensais, pagamento/estorno e projeção; somente juros entram nas despesas analíticas. |
| Contas mensais variáveis | Obrigação recorrente estimada na projeção, confirmação pelo valor real e histórico preservado. |

## Lacunas que ainda merecem decisão de produto

- Pessoas da família não são uma entidade separada: o usuário pode registrar
  a pessoa na fonte da receita, mas não há totais/filtros independentes por
  membro. Isso evita supor como despesas conjuntas devem ser rateadas.
- A reserva informada é declaratória; não é vinculada automaticamente a uma
  conta ou investimento, para não sugerir liquidez que não foi comprovada.
- Dívidas não são importadas de contratos bancários nem calculam taxas
  efetivas, impostos ou seguros. A taxa mensal é informada pelo usuário.
- Contas recorrentes são mensais nesta versão; não há periodicidade semanal,
  anual nem reajuste automático. Assinaturas continuam em seu módulo próprio.
- Não há integração bancária, sincronização ou aconselhamento financeiro
  automatizado. Extratos e saldos continuam locais e controlados pelo usuário.

Essas lacunas são uma fila explícita, não valores presumidos. A próxima
evolução mais útil é estruturar membros da família e regras de rateio, seguida
de importação local de extratos para conciliar planejado e realizado.
