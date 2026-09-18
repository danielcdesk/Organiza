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
- O valor informado numa compra parcelada representa o total da compra; cada parcela entra em sua fatura mensal. Pagamento e histórico definitivo de faturas ainda não foram implementados.
- Investimentos são posições manuais: total aplicado e saldo atual são informados pelo usuário. Rentabilidade é `saldo atual − total aplicado`, e o percentual é calculado sobre o total aplicado. Renda fixa pode guardar tipo, emissor e vencimento. Não há cotação em tempo real, conexão com corretoras ou execução de ordens.
- Taxa de rentabilidade e dia mensal de crédito são informações manuais separadas do resultado realizado: não fazem projeção automática, não alteram saldo e não implicam crédito de rendimento.
# Orçamentos

Cada orçamento é mensal e vinculado a uma categoria. O consumo soma somente despesas da mesma categoria no mesmo ano/mês; receitas e transferências ficam fora do cálculo. O indicador visual é limitado a 100%, mas o valor acima do limite continua explícito para o usuário.

Transações também guardam subcategoria para análises mais detalhadas. Assinaturas são compromissos recorrentes manuais e não criam lançamentos automaticamente nesta etapa.

A distribuição salarial é uma preferência local em três blocos — essenciais, objetivos e livre — e precisa totalizar exatamente 100%. O valor-base considera apenas entradas na categoria **Salário**, registradas ou previstas por uma série salarial ativa para o mês; outras receitas não entram nesse cálculo.
