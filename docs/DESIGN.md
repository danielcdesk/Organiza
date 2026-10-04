# Organiza — sistema visual 0.8

O Organiza usa uma linguagem editorial, silenciosa e local-first: uma base neutra, um acento quente e números fáceis de escanear. A inspiração de produtos financeiros serve apenas para hierarquia e ritmo; não copiamos marcas, mascotes, ilustrações ou funcionalidades.

## Regras de superfície

- A tela tem no máximo dois níveis: canvas e uma superfície tonal de apoio.
- Métricas não recebem caixas individuais. O hero pode receber uma única superfície tonal aquecida.
- Seções de listas usam título e divisor fino de largura total (`HairlineSection`), sem cartões empilhados.
- Bordas, espaçamentos, raios e tamanhos interativos vêm de `OrganizaDesignTokens`.

## Tipografia e números

- O texto usa a família do tema e os estilos de `TextTheme`.
- Valores usam figuras tabulares e contexto textual; nenhum número aparece sem rótulo.
- Datas e valores podem usar ritmo monoespaçado apenas quando isso melhorar a leitura de dados.
- Não há tamanhos fixos nas páginas novas: a escala acompanha o tema e a fonte do sistema.

## Cor e estado

- O laranja identifica ação e marca.
- Verde, vermelho e âmbar são semânticos, sempre acompanhados de ícone e texto.
- Contraste alvo: 4,5:1 para texto e 3:1 para ícones/bordas relevantes.
- Um valor nunca depende apenas da cor para ser compreendido.

## Interação e acessibilidade

- Alvos de toque têm pelo menos 48 dp no celular e foco visível no desktop.
- Navegação inferior tem até cinco destinos, sempre com ícone e rótulo.
- Gráficos têm descrição semântica e tabela alternativa.
- Estados vazios convidam à próxima ação; erros explicam o que aconteceu em linguagem simples.
- Animações decorativas respeitam `MediaQuery.disableAnimationsOf(context)`.

## Componentes

`HeroAmount`, `DeltaText`, `SegmentedRange`, `QuickActionGrid`, `StatusPill`, `HairlineSection` e `AppBottomNav` são os blocos oficiais para as telas redesenhadas. Componentes antigos continuam compatíveis enquanto as telas legadas são migradas gradualmente.

## Visão geral e relatórios

- A Visão geral é operacional: saldo disponível, próxima fatura, próxima assinatura, orçamento restante e até cinco despesas e cinco entradas recentes.
- Gráficos, categorias, comparações, histórico e detalhamento mensal pertencem a Relatórios.
- A Visão geral sempre oferece um acesso explícito ao relatório mensal completo, sem repetir suas análises.
