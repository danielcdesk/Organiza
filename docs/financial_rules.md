# Regras financeiras

## Planejamento familiar e reserva

- Dívidas guardam o principal remanescente e taxa de juros mensal manual, em
  pontos-base. Cada parcela paga é uma única saída da conta; principal reduz a
  dívida, e somente juros aparecem como despesa de consumo nos relatórios. A
  previsão inclui as parcelas futuras estimadas. Estornar uma parcela desfaz a
  saída e repõe o principal numa transação.
- Contas recorrentes são estimativas mensais, ajustadas ao último dia quando
  o dia escolhido não existe no mês. Enquanto ativas, entram na previsão; a
  confirmação registra o valor real como despesa paga e avança o vencimento.
  Pausar ou excluir remove só os vencimentos futuros, sem apagar o histórico.

- O planejamento agrupa lançamentos pela data civil do mês, inclusive
  lançamentos ainda pendentes. Transferências e pagamento de fatura ficam fora;
  parcelas de cartão entram pela competência da fatura, uma única vez.
- Categorias de despesa podem ser essenciais, não essenciais ou não
  classificadas. Lançamentos antigos sem classificação continuam nas despesas
  gerais; uma ocorrência pode ter classificação própria. Receitas sem fonte
  continuam somadas e são exibidas como “Sem fonte”.
- Sobra = receitas − todas as despesas. Taxa de poupança = sobra ÷ receitas;
  com receita zero, a taxa é exibida como zero. Valor negativo explicita déficit.
- Meta de reserva = meses-alvo (padrão 6) × média, em centavos, do custo
  essencial elegível dos três meses civis completos anteriores à data atual.
  O mês em andamento não entra. O usuário pode excluir categorias do cálculo
  e informar manualmente o saldo já reservado; este saldo não movimenta conta
  nem posição de investimento.
- O indicador de investimentos mostra o valor atual das posições cadastradas,
  não aportes do mês nem uma cotação em tempo real.

## Previsão e edição na versão 0.7.0

- A previsão de fechamento parte do saldo confirmado e soma receitas pendentes e desconta despesas pendentes até o último dia do mês, incluindo atrasos de meses anteriores.
- Transferências entre contas próprias não alteram a previsão consolidada. Assinaturas, compras no cartão e salários de séries ainda não materializados não são somados automaticamente.
- A agenda de pendências é ordenada por vencimento; confirmar uma ocorrência altera seu status e, consequentemente, o saldo. Desfazer devolve a ocorrência ao estado pendente.
- Edição de valor/descrição preserva ID, conta, data, tipo, série e status. A edição não se propaga para outras parcelas ou salários.
- Totais do histórico acompanham o filtro ativo e consideram apenas ocorrências confirmadas, com transferências fora de receitas/despesas.

- Datas de negócio são datas civis `yyyy-MM-dd`, sem horário/fuso; timestamps de criação são UTC. Séries mensais ajustam 29/30/31 ao último dia do mês, inclusive em ano bissexto.
- Edição e exclusão de recorrências e parcelamentos oferecem somente esta ocorrência, esta e as próximas, ou todas. Salário recorrente é excluído por ocorrência por padrão; cancelar futuros salários exige ação explícita e confirmação.
- Alterar total de um parcelamento redistribui o total pelas parcelas abrangidas, com os centavos restantes nas primeiras, sem perda nem criação de valor.
- Saldos negativos são válidos para representar cheque especial, respeitando magnitude absoluta inferior a R$ 1 bilhão. O saldo consolidado pode ser negativo; transferências próprias continuam neutras.
- Após exclusão, a interface oferece desfazer; a restauração de todas as linhas é uma única transação.


- Valores monetários são centavos inteiros; `double`, `NaN` e `Infinity` não entram no domínio.
- Saldo de uma conta: saldo inicial + receitas pagas − despesas pagas − transferências enviadas + transferências recebidas.
- Ajustar o saldo atual altera o saldo-base pela diferença observada; movimentações existentes permanecem no histórico e continuam a compor o saldo.
- Receita e despesa sempre pertencem a uma conta. Transferência exige destino diferente da origem, não altera o patrimônio consolidado e, nesta versão, só pode ser única.
- Entradas e saídas mensais consideram a data e somente lançamentos efetivados; transferências ficam fora.
- Disponível para gastar é o saldo atual consolidado. Orçamentos não voltam a subtrair despesas que já compõem o saldo.
- Um lançamento único cria uma ocorrência. Um recorrente repete o mesmo valor mensalmente. Um parcelado divide o valor total entre 2 e 60 parcelas, distribuindo eventuais centavos restantes sem alterar o total.
- Salário recorrente é uma exceção: a série fica registrada, mas só materializa a competência no dia devido. Não tem campo de parcelas/quantidade de meses. A ocorrência nasce pendente até confirmação de recebimento. O planejamento pode mostrar o salário esperado no mês antes da ocorrência, sem confundi-lo com o saldo realizado.
- Ocorrências na data atual ou no passado nascem pagas; ocorrências futuras nascem pendentes. O usuário pode alternar o estado no histórico.
- Cartões guardam apenas nome, bandeira, quatro últimos dígitos, limite, fechamento e vencimento. Nunca armazenar número completo ou CVV. Fechamento e vencimento aceitam 1..31 e são ajustados ao último dia disponível do mês.
- O ciclo começa no dia posterior ao fechamento anterior e termina no próximo fechamento, inclusive. A compra tem data, categoria e subcategoria. O valor informado numa compra parcelada é o total; os centavos restantes são distribuídos nas primeiras parcelas e cada parcela pertence a uma fatura do ciclo.
- Faturas persistidas formam histórico. A corrente fica aberta até fechar, depois fechada até pagamento integral. O vencimento é o primeiro dia configurado após o fechamento, ajustado ao último dia do mês. Pagamento parcial não faz parte da primeira versão.
- Cada parcela consome orçamento e relatórios por categoria/subcategoria da compra e na competência da fatura a que pertence (data de fechamento). O pagamento da fatura é saída de caixa, não nova despesa de consumo, e é excluído de totais analíticos e orçamentos.
- Pagar a fatura registra uma única despesa na conta escolhida, no valor integral, e marca-a paga. Reverter remove a movimentação associada e reabre a fatura; ambas as operações são atômicas. Faturas não pagas entram na previsão na data de vencimento, sem projetar as compras novamente.
- Cartão não pode ser excluído se houver compras, faturas ou pagamentos associados; compras de faturas pagas precisam do estorno antes de serem editadas/removidas.
- Investimentos são posições manuais: total aplicado e saldo atual são informados pelo usuário. Rentabilidade é `saldo atual − total aplicado`, e o percentual é calculado sobre o total aplicado. Renda fixa pode guardar tipo, emissor e vencimento. Não há cotação em tempo real, conexão com corretoras ou execução de ordens.
- Taxa de rentabilidade e dia mensal de crédito são informações manuais separadas do resultado realizado: não fazem projeção automática, não alteram saldo e não implicam crédito de rendimento.
# Orçamentos

Cada orçamento é mensal e vinculado a uma categoria. O consumo soma somente despesas da mesma categoria no mesmo ano/mês; receitas e transferências ficam fora do cálculo. O indicador visual é limitado a 100%, mas o valor acima do limite continua explícito para o usuário.

Transações também guardam subcategoria para análises mais detalhadas. Assinaturas são compromissos recorrentes manuais e não criam lançamentos automaticamente nesta etapa.

A distribuição salarial é uma preferência local em três blocos — essenciais, objetivos e livre — e precisa totalizar exatamente 100%. O valor-base planejado usa a renda mensal informada no perfil quando ela é maior que zero. Sem esse valor, usa o salário registrado ou previsto por série salarial no mês. Essas fontes nunca são somadas entre si para formar a mesma base. A renda do perfil é previsão de orçamento, não lançamento recebido: não altera saldo nem receitas registradas. Outras categorias de receita não entram nessa distribuição.

# Distribuição mensal vigente

A distribuição planejada é registrada por mês de vigência. Alterações no mês
atual não reescrevem versões de meses anteriores; meses futuros herdam a última
versão até uma nova alteração. A migração registra a distribuição legada apenas
no mês em que ocorre, sem atribuí-la retroativamente a meses sem evidência.
Planejamento e Visão Geral usam sempre o mês corrente; Relatórios consulta o
histórico e indica quando ele não está disponível.

# Cartão e pagamento

O emissor é apenas um nome opcional, sem número completo nem CVV. A cor é
visual e não altera cálculos. O pagamento de fatura usa a conta e a data civil
escolhidas; datas futuras não são aceitas como pagamento realizado. A saída é
criada uma vez por fatura fechada, e segunda tentativa falha sem novo débito.

# Metas

O aporte já registrado permanece ao editar uma meta. O novo alvo não pode
ficar abaixo do valor guardado. Tipo, cor, nota e imagem são atributos de
apresentação e não alteram saldo ou transações.
