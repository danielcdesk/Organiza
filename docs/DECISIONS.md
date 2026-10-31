# Decisões de produto

## Execução V3 — decisões confirmadas em 29/10/2026

- Compras no cartão entram na análise por categoria pela data da compra. O caixa e a projeção consideram o vencimento; pagar fatura reduz a conta sem repetir a despesa de categoria. Confirmado pelo dono do produto.
- Dívidas e financiamentos não entram nesta execução, por escolha do dono do produto.
- Contas passam a ter tipo corrente/poupança/carteira/investimento/outra, com BRL como padrão. Arquivar preserva saldo e histórico e remove a conta dos novos seletores; o usuário pode incluir/excluir a conta arquivada do patrimônio, cujos totais são agrupados por moeda sem conversão. Decisão de produto confirmada durante a Fase 2.4.
- Criptografia do banco será ligada por padrão na Fase 4; bloqueio com PIN e biometria opcional. Confirmado pelo dono do produto. Ainda não implementado.
- Totais de fatura serão derivados das compras e parcelas; registros de fatura preservam período e pagamentos.
- Importação OFX/CSV é a alternativa local-first. Não ativar Open Finance nem rede no produto.
- A configuração de SQLite3MultipleCiphers/SQLCipher será verificada na documentação da versão instalada antes da Fase 4.
- Manter sqlite3 e ChangeNotifier. Drift e troca de estado são opcionais e não foram aprovados; não são pré-requisitos das melhorias obrigatórias.
- A senha de backup automático pode ficar no cofre do sistema, conforme autorização do dono do produto. Windows usa DPAPI e Android usa Android Keystore. O plugin `flutter_secure_storage` foi retirado porque a versão compatível exigia ATL ausente no ambiente Windows; as APIs do sistema não adicionam rede nem persistem a senha em SQLite.
- Exclusões do escopo da Fase 2.3 são lógicas: `deleted_at` usa o relógio injetado em UTC, leituras normais ocultam tombstones e backup mantém as linhas para recuperação. Expurgo definitivo e retenção são adiados; a Fase 2.3 não habilita sincronização.
- O plano V3 sugere usar `finance_categories` também em `financial_goals`, mas o código real usa `goal_categories`, com vocabulário próprio (`Reserva`, `Casa`, `Viagem` etc.) e sem tipo receita/despesa. O schema 17 preservará essa distinção e ligará metas a `goal_categories(name)` por FK com atualização em cascata. O nome `goal_category_name` explicita a chave existente; não será criado um vínculo financeiro fictício.

### Correções factuais do plano fornecido

O ZIP usa schema 16, embora as notas 0.9.0 ainda dissessem 15. O estado conhecido já descreve 0.9.0, não apenas 0.6.0. A validação atual executou 108 testes; números antigos de 95/100 são históricos. A referência a Drift como item 3.6 deve ser lida como 3.10. Essas diferenças não alteram o produto solicitado; foram registradas antes da implementação.

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
