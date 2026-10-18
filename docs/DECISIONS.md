# Decisões de produto

## Cartões, faturas e competência de consumo (2026-10-11)

- A compra é o fato de consumo. Orçamentos e relatórios classificam cada parcela pela categoria/subcategoria da compra e pela competência da fatura à qual ela pertence (data de fechamento). O pagamento da fatura é apenas saída de caixa e não volta a consumir orçamento nem entra nos totais analíticos de consumo.
- Cada parcela é vinculada a uma fatura identificada pelo cartão e data de fechamento. A primeira parcela entra no primeiro fechamento no dia da compra ou depois dele; as seguintes avançam mês a mês. Fechamento e vencimento aceitam 1..31 e são limitados ao último dia disponível do mês.
- Faturas são preservadas como histórico com status aberta, fechada ou paga. A corrente fica aberta até o fechamento; então fica fechada até o pagamento integral. O pagamento registra uma única despesa na conta escolhida e pode ser revertido; reverter remove a saída e reabre a fatura. Pagamento parcial não entra na primeira entrega.
- Cartão não pode ser excluído se tiver compras, faturas ou pagamentos associados. Compra ligada a fatura paga não pode ser editada/excluída antes de reverter o pagamento.
- A previsão inclui faturas fechadas não pagas na data de vencimento. Compras não são projetadas de novo como saída de caixa, evitando duplicar a obrigação.

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
# Datas de negócio e séries financeiras (2026-10-11)

- Datas civis financeiras são representadas por `BusinessDate` como `yyyy-MM-dd`; UTC é apenas o transporte estável do ano/mês/dia, não um instante. `created_at` permanece timestamp UTC.
- Schema 18 normaliza datas ISO antigas pelo dia civil escrito originalmente. Schema 19 armazena exclusões de ocorrências salariais sem apagar a programação da série.
- Ao editar/excluir série recorrente ou parcelada, o usuário escolhe ocorrência, esta e próximas, ou série inteira. O padrão é apenas a ocorrência. Salários têm ação separada e confirmada para cancelar a recorrência.
- Total de parcelamento editado é redistribuído entre as parcelas selecionadas com centavos restantes nas primeiras parcelas. Cada edição/exclusão multi-linha é atômica.
- Saldos negativos são permitidos como cheque especial, dentro do limite de segurança monetária; transferências continuam neutras no consolidado. Exclusões exibem ação temporária de desfazer.
- A atualização de ocorrências vencidas roda ao retomar o app e também por timer; ambos consultam o `Clock` injetado.
