# Organiza

Aplicativo pessoal de organização financeira para Windows, pensado para funcionar localmente e sem internet. O produto reúne contas, movimentações, cartões, orçamentos, assinaturas, investimentos, planejamento, metas e relatórios em uma única base SQLite.

## Interface

![Dashboard do Organiza](docs/screenshots/dashboard.png)

![Módulo de cartões](docs/screenshots/cards.png)

![Investimentos](docs/screenshots/investments.png)

![Nova transação com conta identificada](docs/screenshots/transaction-dialog.png)

![Relatórios](docs/screenshots/reports.png)

![Orçamentos](docs/screenshots/budgets.png)

![Assinaturas](docs/screenshots/subscriptions.png)

![Planejamento salarial](docs/screenshots/planning.png)

![Metas financeiras](docs/screenshots/goals.png)

![Mapa anual de gastos](docs/screenshots/reports-roadmap.png)

## Funcionalidades

- Contas com saldo inicial, saldo calculado e ícones visuais de Nubank, Inter, Caixa, Itaú, Banco do Brasil, Bradesco, Santander ou banco genérico
- Receitas, despesas e transferências entre contas, com conta identificada por ícone e data escolhida pelo usuário
- Lançamentos únicos, recorrentes ou parcelados; ocorrências futuras ficam pendentes até a confirmação do usuário
- Histórico de movimentações com fluxo mensal de entradas, saídas e resultado
- Busca e filtros por tipo, categoria, subcategoria e descrição, com exclusão confirmada
- Visão geral com entradas, saídas e disponível para gastar
- Tarefas simples com conclusão persistente
- Cartões com limite, fechamento, vencimento, ciclo atual, compras manuais e parcelas distribuídas por fatura
- Carteira de investimentos consolidada com patrimônio, resultado, rentabilidade, alocação por classe e exclusão de posições
- Renda fixa organizada por tipo, emissor e vencimento: CDB, LCI, LCA, Tesouro Selic/IPCA/Prefixado, debêntures, CRI, CRA, poupança e outros
- Relatórios por período, evolução mensal, comparação de entradas e saídas, ranking de gastos e exportação CSV local
- Relatórios com gastos e receitas por categoria e mapa anual de gastos no estilo contribution graph
- Orçamentos mensais por categoria, com consumo calculado a partir das despesas e indicador de limite
- Assinaturas recorrentes com valor, dia de cobrança e categoria
- Categorias e subcategorias de receitas e despesas, incluindo Bar e bebidas e Cafeterias, com criação pelo usuário durante o lançamento
- Planejamento com salário identificado pelas receitas e distribuição ajustável entre essenciais, objetivos e livre
- Metas financeiras com prazo opcional, valor inicial, aportes, conclusão e persistência local
- Distribuição salarial persistida e normalizada para sempre totalizar 100%
- Tema claro, escuro ou do sistema; ocultação de valores; busca local e atalhos de teclado
- Transições suaves entre módulos, barras de progresso animadas e tela cheia com F11 ou pelo botão no topo
- Dashboard integrado com orçamento usado, assinaturas, taxa de economia e atalhos contextuais
- SQLite local, sem login, analytics ou telemetria

## Tecnologias

Flutter, Dart e SQLite (`sqlite3`). O acesso ao banco é isolado em `lib/database/`; a evolução para Drift está registrada no roadmap técnico.

## Arquitetura

`presentation → application → database/domain`. Widgets não executam SQL e os cálculos monetários usam centavos inteiros. Lançamentos pendentes permanecem no planejamento, mas não alteram o saldo realizado.

Leia [a arquitetura](docs/architecture.md), [as regras financeiras](docs/financial_rules.md), [a base de pesquisa](docs/research_basis.md) e [a matriz de funcionalidades](docs/feature_matrix.md) antes de evoluir o projeto.

## Instalação

1. Instale o [Flutter](https://docs.flutter.dev/get-started/install/windows/desktop) com suporte a Windows Desktop.
2. Gere o runner Windows ausente neste ambiente com `flutter create --platforms=windows .`.
3. Execute `flutter pub get`.
4. Rode `flutter run -d windows`.

## Desenvolvimento

Atalhos disponíveis: `Ctrl+K` para busca local, `Ctrl+N` para lançamento, `Ctrl+Shift+N` para tarefa, `Ctrl+,` para configurações e `F11` para tela cheia.

## Testes

```powershell
flutter analyze
flutter test
flutter test integration_test
```

## Build Windows

```powershell
flutter build windows --release
```

O build precisa ser executado em uma máquina com Flutter e as ferramentas Windows configuradas. Veja o estado de validação em [docs/known_good_state.md](docs/known_good_state.md).

## Estrutura

```text
lib/
  application/  # estado e casos de uso iniciais
  database/     # schema, migrações e consultas SQLite
  domain/       # entidades e regras financeiras puras
  presentation/ # interface desktop
  services/     # fronteiras de serviços, como backup
docs/           # contratos técnicos e registro de qualidade
test/           # regras puras
integration_test/
```

## Privacidade

Dados ficam no computador. Não envie banco de dados, backups, exportações, logs ou arquivos `.env` ao GitHub; as regras estão no `.gitignore`.

## Roadmap

Pagamento e histórico de faturas, edição de lançamentos/orçamentos, baixa em série, backup/restauração com fluxo de confirmação e migração do acesso SQLite para Drift. Android, iOS, sincronização bancária, importação de notas e cotações automáticas são futuras e opcionais.

Ferramentas de IA auxiliaram no desenvolvimento inicial; o produto não contém IA, LLM, analytics nem integração externa.
