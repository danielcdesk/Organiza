# Regras financeiras

## Previsão e edição na versão 0.7.0

- A previsão de fechamento parte do saldo confirmado e soma receitas pendentes e desconta despesas pendentes até o último dia do mês, incluindo atrasos de meses anteriores.
- Transferências entre contas próprias não alteram a previsão consolidada. Assinaturas, compras no cartão e salários de séries ainda não materializados não são somados automaticamente.
- A agenda de pendências é ordenada por vencimento; confirmar uma ocorrência altera seu status e, consequentemente, o saldo. Desfazer devolve a ocorrência ao estado pendente.
- Edição de valor/descrição preserva ID, conta, data, tipo, série e status. A edição não se propaga para outras parcelas ou salários.
- Totais do histórico acompanham o filtro ativo e consideram apenas ocorrências confirmadas, com transferências fora de receitas/despesas.


- Valores monetários são centavos inteiros; `double`, `NaN` e `Infinity` não entram no domínio.
- Saldo de uma conta: saldo inicial + receitas pagas − despesas pagas − transferências enviadas + transferências recebidas.
- Ajustar o saldo atual altera o saldo-base pela diferença observada; movimentações existentes permanecem no histórico e continuam a compor o saldo.
- Receita e despesa sempre pertencem a uma conta. Transferência exige destino diferente da origem, não altera o patrimônio consolidado e, nesta versão, só pode ser única.
- Entradas e saídas mensais consideram a data e somente lançamentos efetivados; transferências ficam fora.
- Disponível para gastar é o saldo atual consolidado. Orçamentos não voltam a subtrair despesas que já compõem o saldo.
- Um lançamento único cria uma ocorrência. Um recorrente repete o mesmo valor mensalmente. Um parcelado divide o valor total entre 2 e 60 parcelas, distribuindo eventuais centavos restantes sem alterar o total.
- Salário recorrente é uma exceção: a série fica registrada, mas só materializa a competência no dia devido. Não tem campo de parcelas/quantidade de meses. A ocorrência nasce pendente até confirmação de recebimento. O planejamento pode mostrar o salário esperado no mês antes da ocorrência, sem confundi-lo com o saldo realizado.
- Ocorrências na data atual ou no passado nascem pagas; ocorrências futuras nascem pendentes. O usuário pode alternar o estado no histórico.
- Cartões guardam apenas nome, bandeira, quatro últimos dígitos, limite, fechamento e vencimento. Nunca armazenar número completo ou CVV.
- O ciclo atual começa no dia posterior ao fechamento anterior e termina no fechamento seguinte, inclusive.
- Fatura em aberto é a soma das compras manuais do ciclo atual. Limite disponível é `limite total − fatura em aberto`.
- O valor informado numa compra parcelada representa o total da compra; cada parcela entra em sua fatura mensal. O usuário marca manualmente quais parcelas já pagou, e o cartão mostra a quantidade paga, a quantidade restante e a barra de progresso. Essa marcação fica vinculada à compra do cartão: não cria despesa, não altera saldo de conta e não confirma uma transação financeira. O histórico definitivo de faturas ainda não foi implementado.
- Investimentos são posições manuais: total aplicado e saldo atual são informados pelo usuário. Rentabilidade é `saldo atual − total aplicado`, e o percentual é calculado sobre o total aplicado. Renda fixa pode guardar tipo, emissor e vencimento. Não há cotação em tempo real, conexão com corretoras ou execução de ordens.
- Taxa de rentabilidade e dia mensal de crédito são informações manuais separadas do resultado realizado: não fazem projeção automática, não alteram saldo e não implicam crédito de rendimento.

## Faturas do cartão — decisão de competência e caixa (schema 18)

- A compra inteira entra nas despesas por categoria na **data da compra**, mesmo se parcelada. Exemplo: compra de R$ 300,00 em 3 parcelas no dia 5 de janeiro aparece como R$ 300,00 na categoria de janeiro.
- As faturas distribuem o desembolso em 3 parcelas de R$ 100,00. Se o cartão fecha dia 10 e vence dia 17, a primeira parcela vence em janeiro; as próximas, em fevereiro e março. A projeção da conta deve usar esses vencimentos enquanto não houver pagamento confirmado (integração ainda pendente nesta fase).
- Pagar R$ 60,00 da fatura de janeiro reduz a conta em R$ 60,00 e deixa R$ 40,00 pendentes. Esse lançamento tem marcador de sistema `card_payment` e **não entra novamente** no total de despesa por categoria, orçamento ou ranking de gastos.
- O estorno remove juntos o pagamento da fatura e o lançamento na conta, restaurando o saldo e o valor pendente.
- Marcações manuais antigas de parcelas pagas não identificavam conta nem valor; continuam separadas dos pagamentos reais de fatura e não são convertidas automaticamente.
# Orçamentos

Cada orçamento é mensal e vinculado a uma categoria. O consumo soma somente despesas da mesma categoria no mesmo ano/mês; receitas e transferências ficam fora do cálculo. O indicador visual é limitado a 100%, mas o valor acima do limite continua explícito para o usuário.

Transações também guardam subcategoria para análises mais detalhadas. Assinaturas são compromissos recorrentes manuais e não criam lançamentos automaticamente nesta etapa.

A distribuição salarial é uma preferência local em três blocos — essenciais, objetivos e livre — e precisa totalizar exatamente 100%. Quando há renda mensal positiva informada no perfil, ela é a base do planejamento. Se o perfil não informa renda, a base soma os lançamentos avulsos de **Salário** no mês e as séries salariais ativas para o mês. Ocorrências materializadas dessas séries não são somadas novamente; outras categorias de receita não entram no cálculo.
