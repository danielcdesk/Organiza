# Decisões de produto

## Projeção diária de saldo

A projeção diária começa no saldo consolidado confirmado de hoje. Lançamentos
confirmados não são aplicados novamente. Lançamentos pendentes vencidos são
considerados no dia atual; os demais entram na data prevista.

Transferências entre contas próprias têm efeito negativo na conta de origem e
positivo na conta de destino, mas efeito zero no saldo consolidado. A projeção
mantém os saldos por conta para representar esse movimento.

Parcelas e recorrências já materializadas são consideradas como ocorrências
individuais. Quando uma série informa uma ocorrência futura ausente, a regra
expande a série mensalmente até o número cadastrado, sem duplicar ocorrências
existentes. Salários programados são expandidos mensalmente; um dia 29, 30 ou
31 é ajustado para o último dia disponível do mês.

## Pode gastar por dia

`pode gastar por dia = max(0, menor saldo projetado até o próximo salário / dias restantes)`

O menor saldo considera os pontos anteriores ao dia do próximo salário. Os
`dias restantes` são a diferença em dias entre hoje e o próximo salário. O
resultado usa centavos inteiros e divisão inteira para não criar valor acima do
limite seguro. Se não houver próximo salário projetado ou se ele ocorrer hoje,
o valor exibido é `R$ 0,00`.
