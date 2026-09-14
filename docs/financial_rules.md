# Regras financeiras

- Valores monetários são centavos inteiros; `double`, `NaN` e `Infinity` não entram no domínio.
- Saldo de uma conta: saldo inicial + receitas pagas − despesas pagas − transferências enviadas + transferências recebidas.
- Receita e despesa sempre pertencem a uma conta. Transferência exige destino diferente da origem, não altera o patrimônio consolidado e, nesta versão, só pode ser única.
- Entradas e saídas mensais consideram a data e somente lançamentos efetivados; transferências ficam fora.
- Disponível para gastar é o saldo atual consolidado. Orçamentos não voltam a subtrair despesas que já compõem o saldo.
- Um lançamento único cria uma ocorrência. Um recorrente repete o mesmo valor mensalmente. Um parcelado divide o valor total entre 2 e 60 parcelas, distribuindo eventuais centavos restantes sem alterar o total.
- Ocorrências na data atual ou no passado nascem pagas; ocorrências futuras nascem pendentes. O usuário pode alternar o estado no histórico.
- Cartões guardam apenas nome, bandeira, quatro últimos dígitos, limite, fechamento e vencimento. Nunca armazenar número completo ou CVV.
- O ciclo atual começa no dia posterior ao fechamento anterior e termina no fechamento seguinte, inclusive.
- Fatura em aberto é a soma das compras manuais do ciclo atual. Limite disponível é `limite total − fatura em aberto`.
- O valor informado numa compra parcelada representa o total da compra; cada parcela entra em sua fatura mensal. Pagamento e histórico definitivo de faturas ainda não foram implementados.
- Investimentos são posições manuais: total aplicado e saldo atual são informados pelo usuário. Rentabilidade é `saldo atual − total aplicado`, e o percentual é calculado sobre o total aplicado. Renda fixa pode guardar tipo, emissor e vencimento. Não há cotação em tempo real, conexão com corretoras ou execução de ordens.
# Orçamentos

Cada orçamento é mensal e vinculado a uma categoria. O consumo soma somente despesas da mesma categoria no mesmo ano/mês; receitas e transferências ficam fora do cálculo. O indicador visual é limitado a 100%, mas o valor acima do limite continua explícito para o usuário.

Transações também guardam subcategoria para análises mais detalhadas. Assinaturas são compromissos recorrentes manuais e não criam lançamentos automaticamente nesta etapa.

A distribuição salarial é uma preferência local em três blocos — essenciais, objetivos e livre — e precisa totalizar exatamente 100%. O valor-base continua sendo a soma das receitas do mês.
