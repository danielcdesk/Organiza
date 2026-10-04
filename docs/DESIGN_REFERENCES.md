# Princípios de design das referências

Data da análise: 2026-09-29

Este documento extrai princípios de composição, hierarquia e interação das referências fornecidas. As referências são inspiração estrutural; não são modelos para cópia visual.

## Limitações da evidência

Os cinco arquivos declarados (`docs/refs/desktop-dashboard-conceito.webp`, `coinbase-boas-vindas.png`, `coinbase-home.png`, `coinbase-ativo-detalhe.png` e `coinbase-watchlist.png`) não estavam presentes nesta cópia do projeto durante a análise. A leitura abaixo foi feita a partir das imagens anexadas na conversa. A imagem extra `a3a79b99802a73a84e7a5e6ddac3e606.jpg` foi recebida, mas não foi atribuída a uma das cinco referências nomeadas e, por isso, não foi usada como evidência principal.

`docs/DESIGN.md` também não existe nesta cópia. As decisões abaixo aplicam as regras explicitadas na solicitação: no máximo dois níveis de superfície, uso de tokens, contraste mínimo de 4,5:1, nenhuma informação somente por cor e textos sem flexões parentéticas como “(s)”.

As medidas são estimativas visuais. Elas servem para orientar tokens e proporções, não para reproduzir pixels das referências.

## Leitura das referências

### `desktop-dashboard-conceito.webp`

1. É um dashboard desktop escuro, com uma barra superior curta e navegação textual no topo.
2. O conteúdo começa com um título de página e uma ação primária de transferência no canto direito.
3. A coluna esquerda concentra um cartão de meio de pagamento e uma meta anual.
4. A área superior direita divide saldo atual, receita e ativos em módulos compactos.
5. A parte inferior direita usa uma tabela larga de transações como área de maior densidade.
6. O saldo e a receita recebem gráficos pequenos, enquanto a tabela usa linhas e cabeçalhos.
7. A maior parte das informações está dentro de cartões escuros com bordas ou sombras discretas.
8. Verde, vermelho e amarelo indicam estados de transação, e o texto também informa o estado.
9. Há uma hierarquia clara de dados, mas muitos módulos competem quando vistos em conjunto.

### `coinbase-boas-vindas.png`

1. É uma tela móvel de boas-vindas em fundo quase preto e sem navegação persistente.
2. Uma ilustração colorida ocupa a região central e funciona como foco de identidade.
3. O título fica abaixo da ilustração, centralizado, com poucas palavras e grande escala.
4. O texto legal aparece em escala menor e contém links destacados.
5. O botão primário é largo, claro e fica próximo da parte inferior da tela.
6. A ação secundária aparece como texto, sem competir visualmente com o botão.
7. Há praticamente um único nível de superfície: o canvas e o botão destacado.
8. O espaçamento vertical é generoso, com poucos elementos simultâneos.
9. A estrutura reduz a decisão inicial a criar algo novo ou continuar com algo existente.

### `coinbase-home.png`

1. É uma home móvel com cabeçalho de conta, saldo total e ações rápidas.
2. A parte superior usa uma área aberta, separadores horizontais e pouca moldura.
3. Um banner de recompensa aparece antes da lista principal e chama atenção pela cor.
4. A watchlist é apresentada como seção independente, com título e cartão vazio convidativo.
5. A seção de trocas usa cartões horizontais que sugerem rolagem lateral.
6. O rodapé mantém uma navegação persistente com cinco ícones.
7. O azul sinaliza navegação selecionada e verde ou vermelho sinalizam variação de mercado.
8. A composição mistura linhas divisórias, cartões e áreas abertas em uma mesma tela.
9. A ordem é orientada a descoberta e conversão, além de consulta de saldo.

### `coinbase-ativo-detalhe.png`

1. A tela começa com voltar, ícone do ativo, nome da métrica e ação de acompanhar.
2. O preço atual é o maior elemento textual da parte superior.
3. A variação aparece imediatamente abaixo com seta, sinal e cor.
4. O gráfico ocupa uma faixa larga e usa uma linha com preenchimento pontilhado.
5. Filtros de período ficam alinhados abaixo do gráfico, com um período selecionado.
6. O saldo do usuário vem depois da visualização, separado por bastante espaço.
7. As ações ficam em uma grade de oito itens, com ícones circulares e rótulos.
8. O rodapé mantém a navegação persistente, mesmo em uma tela de detalhe.
9. A tela prioriza uma métrica, sua variação, seu histórico e ações relacionadas.

### `coinbase-watchlist.png`

1. A tela usa um título grande de lista e uma ação de busca no canto superior direito.
2. Cada item tem ícone, nome, código curto, preço e variação alinhados em duas áreas.
3. A lista não usa um cartão individual por item; o espaço aberto separa as linhas.
4. O preço fica alinhado à direita, favorecendo comparação vertical rápida.
5. A variação combina seta, sinal numérico e cor vermelha ou verde.
6. Há poucos itens visíveis e muito respiro entre as linhas.
7. Uma ação grande fica ancorada no final da área de conteúdo.
8. O rodapé usa novamente ícones como navegação persistente.
9. A tela é um exemplo de lista simples com uma ação de continuação bem destacada.

## Princípios mensuráveis e decisões

| referência | princípio | decisão | onde aplicar | risco |
|---|---|---|---|---|
| desktop-dashboard-conceito.webp | Métrica principal estimada em 2 a 3 vezes o tamanho dos rótulos auxiliares. | Organiza: ADAPTAR; Flow State: ADAPTAR. | Disponível no mês; foco do dia ou próxima ação. | Números grandes sem contexto viram decoração. Todo número terá rótulo e contexto. |
| desktop-dashboard-conceito.webp | Dois a três níveis visuais de superfície parecem existir: canvas, cartões e elementos internos. | Organiza: ADAPTAR para no máximo dois níveis; Flow State: ADAPTAR para canvas e painel elevado. | Dashboards desktop. | Herdar três níveis cria profundidade falsa e dificulta contraste. |
| desktop-dashboard-conceito.webp | Tabelas e listas usam divisores e cabeçalho em vez de um cartão por linha. | Organiza: ADOTAR; Flow State: ADOTAR. | Últimos lançamentos, transações, tarefas e histórico. | Divisores fracos podem sumir no tema escuro; usar token de contraste mínimo. |
| desktop-dashboard-conceito.webp | Cards têm raio estimado de 16 a 24 px, aproximadamente 8% a 14% da altura dos módulos compactos. | Organiza: ADAPTAR por token único; Flow State: ADAPTAR. | Painéis principais, não cada linha de lista. | Raio grande em tudo deixa o produto infantil ou excessivamente arredondado. |
| desktop-dashboard-conceito.webp | Densidade alta na tabela e baixa nos cards de resumo; o respiro separa os grupos, não cada dado. | Organiza: ADAPTAR; Flow State: ADAPTAR. | Desktop com duas colunas e listas compactas. | Em fonte 200%, a densidade pode gerar overflow; listas devem quebrar verticalmente. |
| desktop-dashboard-conceito.webp | Cores de marca ficam concentradas em ações; verde, vermelho e amarelo têm função semântica. | Organiza: ADOTAR com laranja da marca; Flow State: ADOTAR com um acento por tema. | Ações, sucesso, atraso, erro e progresso. | Cor sozinha viola acessibilidade; sempre combinar ícone, texto ou sinal. |
| desktop-dashboard-conceito.webp | Status usa cor mais texto curto e selo, com variação de forma e posição. | Organiza: ADOTAR; Flow State: ADOTAR. | Situação de conta, tarefa e lançamento. | Selo pequeno demais pode falhar em fonte ampliada. |
| desktop-dashboard-conceito.webp | A ação principal aparece no topo direito; ações secundárias ficam próximas do módulo. | Organiza: ADAPTAR para ação local e botão “+” fixo; Flow State: ADAPTAR. | Registrar gasto, criar tarefa e abrir relatório. | Duplicar a mesma ação no topo, card e rodapé aumenta competição. |
| coinbase-boas-vindas.png | Ilustração ocupa estimados 30% a 40% da altura útil e o título mede cerca de 2 vezes o texto legal. | Organiza: ADOTAR a proporção; Flow State: ADAPTAR. | Primeira tela de cada app. | Copiar composição e arte literalmente cria dependência de referência externa. |
| coinbase-boas-vindas.png | Um único botão primário tem largura estimada de 85% a 90% da tela e altura de pelo menos 48 dp. | Organiza: ADOTAR; Flow State: ADOTAR. | “Começar” e ação inicial da produtividade. | Botão largo demais em desktop perde precisão; limitar por largura máxima. |
| coinbase-boas-vindas.png | O link secundário fica abaixo do primário, com escala menor e sem container próprio. | Organiza: ADOTAR; Flow State: ADOTAR. | “Já tenho um backup”; continuar configuração. | Contraste baixo em link secundário; manter 4,5:1 e foco visível. |
| coinbase-boas-vindas.png | Texto legal é pequeno, centralizado e separado do CTA por um intervalo curto. | Organiza: ADAPTAR para no mínimo 12 a 14 sp e quebra em várias linhas; Flow State: ADAPTAR. | Política de privacidade e termos locais. | Texto pequeno pode não suportar 200%; permitir crescimento e rolagem. |
| coinbase-boas-vindas.png | A tela tem um nível de superfície dominante e uma superfície de ação clara. | Organiza: ADOTAR, respeitando máximo de dois níveis; Flow State: ADOTAR. | Boas-vindas sem cards decorativos. | Gradientes e brilho podem reduzir legibilidade e aumentar ruído visual. |
| coinbase-home.png | O saldo principal aparece cerca de 2 a 3 vezes maior que os rótulos do cabeçalho. | Organiza: ADAPTAR; Flow State: ADAPTAR para métrica diária. | Saldo atual ou disponível no mês. | Exibir saldo sem período ou definição cria interpretação errada. |
| coinbase-home.png | Divisores horizontais separam grupos e reduzem o número de cartões independentes. | Organiza: ADOTAR; Flow State: ADOTAR. | Seções de dashboard e listas. | Divisor com contraste abaixo de 3:1 falha como borda; usar token acessível. |
| coinbase-home.png | Ações rápidas aparecem como ícones circulares com rótulo; o alvo visual é aproximadamente 56 a 72 px. | Organiza: ADAPTAR com no mínimo 48 dp; Flow State: ADAPTAR. | Atalhos para lançamento, tarefa e relatório. | Ícone sem rótulo ou ação só por cor não será herdado. |
| coinbase-home.png | Banner promocional ocupa posição anterior ao conteúdo principal e usa forte contraste de cor. | Organiza: REJEITAR; Flow State: REJEITAR. | Nenhum dos dois apps. | Upsell e promoção desviam da tarefa principal e não pertencem ao produto local-first. |
| coinbase-home.png | Navegação inferior usa ícones sem rótulos visíveis em alguns estados. | Organiza: REJEITAR; Flow State: REJEITAR. | Navegação móvel. | Falta de rótulo, ordem difícil de memorizar e possível dependência de forma/cor. |
| coinbase-ativo-detalhe.png | A métrica, a variação e o gráfico formam uma sequência vertical: valor, contexto, histórico, ação. | Organiza: ADOTAR; Flow State: ADAPTAR. | Projeção de saldo, detalhe de conta e evolução de hábito. | Gráfico financeiro deve ter tabela ou descrição textual, não apenas desenho. |
| coinbase-ativo-detalhe.png | Filtros de período são pílulas pequenas, com um estado selecionado visualmente. | Organiza: ADAPTAR com texto e estado semântico; Flow State: ADAPTAR. | 30/60/90 dias; hoje/semana/mês. | Pílulas pequenas e dependentes de cor podem falhar em toque e acessibilidade. |
| coinbase-ativo-detalhe.png | Grade de ações usa quatro colunas e duas linhas, com rótulo abaixo do ícone. | Organiza: ADAPTAR para duas ou três colunas; Flow State: ADAPTAR. | Ações financeiras e rotinas. | Quatro colunas não cabem em telas menores ou com fonte 200%. |
| coinbase-ativo-detalhe.png | Linha e área do gráfico usam uma cor de destaque, enquanto o estado positivo usa verde. | Organiza: ADAPTAR; Flow State: ADAPTAR. | Gráficos de tendência e progresso. | Não usar cor como única indicação; incluir seta, sinal, legenda ou texto. |
| coinbase-watchlist.png | Linhas de lista usam alinhamento à esquerda para identidade e à direita para valores; não há card por item. | Organiza: ADOTAR; Flow State: ADOTAR. | Lançamentos, contas, tarefas e metas. | Textos longos podem colidir com valores; reservar coluna flexível e truncamento acessível. |
| coinbase-watchlist.png | Muito respiro entre linhas, estimado em 1,5 a 2 vezes a altura do texto principal. | Organiza: ADAPTAR; Flow State: ADOTAR. | Listas de alta prioridade. | Respiro excessivo reduz quantidade visível; definir limite de itens e “Ver todas”. |
| coinbase-watchlist.png | Ação de busca fica no cabeçalho e a ação de continuação fica ancorada no final. | Organiza: ADAPTAR; Flow State: ADAPTAR. | Busca contextual e criação de primeiro item. | Ação fixa pode esconder conteúdo com teclado ou fonte ampliada. |
| coinbase-watchlist.png | Variação combina seta, sinal numérico e cor, em vez de depender apenas da cor. | Organiza: ADOTAR; Flow State: ADOTAR. | Atraso, aumento, queda e progresso. | Seta ambígua sem texto alternativo; incluir label semântico completo. |

## Aplicação por produto

### Organiza

- ADOTAR a hierarquia valor principal → contexto → próximos itens → ação.
- ADAPTAR o dashboard para uma superfície de fundo e uma superfície elevada, sem reproduzir a grade de cartões da referência.
- ADOTAR listas com divisores quando a comparação entre lançamentos for mais importante que a separação visual.
- ADAPTAR a cor laranja da logo como marca; reservar vermelho para atraso/erro e verde para entrada ou situação positiva.
- ADOTAR sinal, seta e texto junto da cor em variações financeiras.
- REJEITAR preços em tempo real, ativos cripto, banners promocionais e navegação somente por ícones.
- Aplicar no onboarding o padrão estrutural de ilustração central, um CTA e link secundário, mas com ilustração vetorial própria do Organiza.

### Flow State

- ADOTAR canvas escuro, escala generosa e um acento por tema.
- ADAPTAR o hero para representar foco do dia, próxima ação ou consistência, nunca saldo ou preço.
- ADOTAR heatmaps, linhas de tendência e telemetria apenas quando explicarem ritmo ou progresso.
- ADOTAR listas abertas com divisores e bastante respiro para tarefas e hábitos.
- ADAPTAR a grade de ações para comandos de rotina, mantendo rótulos visíveis.
- REJEITAR padrões de conversão financeira, banners de upsell e qualquer linguagem de carteira ou mercado.
- Respeitar movimento reduzido: gráficos decorativos e transições não podem ser essenciais para entender o estado.

## Não copiar

- Logos, wordmarks, símbolos ou marcas da Coinbase, Mobbins ou qualquer outro produto da referência.
- Mascotes, personagens, ilustrações, moedas, tokens e imagens de banco.
- Textos, nomes, rótulos, números, preços ou exemplos de transação das imagens.
- Combinações exatas de cores, especialmente azul de seleção, laranja de gráfico e gradientes usados nas referências.
- Funcionalidades cripto, preços em tempo real, watchlist de ativos ou linguagem de compra, troca e saque.
- Banners de recompensa, promoção, conversão ou upsell.
- Barra de navegação composta somente por ícones sem rótulos acessíveis.
- Cartões de crédito, endereços de carteira, códigos de ativos e porcentagens de mercado.
- Escala, espaçamento e composição pixel a pixel das telas anexadas.

## Problemas de acessibilidade observados nas referências

- Algumas navegações inferiores dependem de ícones sem rótulo textual visível; isso não deve ser herdado.
- Textos secundários cinza sobre preto parecem próximos do limite de contraste e precisam de medição real antes de qualquer adoção.
- Variações verdes e vermelhas podem ser percebidas como apenas cor; Organiza e Flow State devem adicionar texto, sinal ou ícone.
- Gráficos dependem da leitura visual da linha, preenchimento ou pontilhado; os dois apps precisam de descrição textual e tabela alternativa quando o dado for relevante.
- Filtros de período e estados selecionados usam principalmente preenchimento ou cor; o estado deve ser anunciado semântico e textualmente.
- A grade de ações pode perder legibilidade em fonte ampliada; o layout deve quebrar em menos colunas sem corte.
- Tabelas desktop têm textos pequenos e muitas colunas; em 200% devem permitir rolagem ou reflow, sem compressão ilegível.
- Textos legais e secundários precisam continuar legíveis em 200% e não podem ficar presos a uma única linha.
- Ícones circulares só são seguros quando o alvo total mantém pelo menos 48 dp no Android e 44 px no desktop.
- Movimento, brilho e transições decorativas não podem ser necessários para reconhecer estado ou concluir uma ação.

## Próximo uso

Este documento orienta a tela de boas-vindas, o dashboard financeiro do Organiza e os componentes de foco do Flow State. Ele não autoriza copiar os arquivos de referência nem substitui testes de contraste, semântica, foco, fonte ampliada e goldens.
