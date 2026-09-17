---
project: Organiza
artifact: Mega Prompt de Implementação
target_platform: Windows
future_platforms:
  - Android
  - iOS
primary_stack:
  - Flutter
  - Dart
  - SQLite
  - Drift
mode: local-first
internet_required: false
ai_features_inside_product: false
habits_module: false
version: 2.0
---

# ORGANIZA — MEGA PROMPT DE IMPLEMENTAÇÃO

## 0. COMO ESTE ARQUIVO DEVE SER USADO

Este documento é a especificação principal do projeto **Organiza**.

Você deve tratá-lo como um **contrato de implementação**.

Não entregue somente explicações, mockups ou exemplos isolados.
Implemente o projeto real, execute testes, valide os fluxos e mantenha um registro técnico do que está funcionando.

Ao receber uma nova solicitação futura para este projeto:

1. Leia este arquivo.
2. Leia os arquivos de estado e testes já existentes no projeto.
3. Identifique o que já está funcionando.
4. Preserve o comportamento aprovado.
5. Faça a alteração solicitada.
6. Execute testes relacionados.
7. Execute testes de regressão.
8. Só considere a alteração concluída quando o estado anterior continuar funcionando.

---

# 1. MISSÃO

Atue simultaneamente como:

- arquiteto de software sênior;
- desenvolvedor Flutter/Dart sênior;
- especialista em SQLite e Drift;
- UX/UI Designer;
- engenheiro de segurança;
- engenheiro de testes;
- especialista em aplicações Windows;
- arquiteto de aplicações multiplataforma.

Sua missão é construir o aplicativo **Organiza**.

O Organiza deve ser inicialmente um aplicativo para **Windows**, totalmente local e offline, com arquitetura preparada desde o início para futura portabilidade para:

- Android;
- iOS.

Não quero um protótipo.

Quero um produto funcional, persistente, testável, organizado e utilizável diariamente.

---

# 2. CONCEITO DO PRODUTO

Nome:

**Organiza**

Conceito:

**VIDA • FINANÇAS • FOCO**

O Organiza deve centralizar:

- finanças pessoais;
- contas;
- cartões de crédito;
- receitas;
- despesas;
- transferências;
- contas futuras;
- recorrências;
- orçamento;
- metas financeiras;
- investimentos;
- tarefas;
- planejamento;
- metas pessoais;
- hidratação;
- relatórios.

## NÃO IMPLEMENTAR

Não implementar:

- sistema de hábitos;
- streak;
- XP;
- níveis;
- medalhas;
- gamificação;
- inteligência artificial dentro do produto;
- chat com IA;
- LLM;
- machine learning.

O Organiza deve ser uma ferramenta de organização, não um jogo.

---

# 3. PRINCÍPIOS DO PRODUTO

O aplicativo deve seguir três ideias:

**Clareza. Controle. Rapidez.**

Ao abrir o aplicativo, o usuário deve conseguir entender rapidamente:

- quanto possui;
- quanto recebeu;
- quanto gastou;
- quanto ainda pode gastar;
- quais contas estão próximas;
- quanto do limite do cartão está sendo usado;
- quais tarefas precisam de atenção;
- quais metas estão em andamento.

Evitar excesso de informação.

---

# 4. REGRA FUNDAMENTAL — LOCAL FIRST

A primeira versão deve funcionar:

**100% LOCAL E OFFLINE.**

Nenhuma função principal pode depender de:

- servidor remoto;
- Supabase;
- Firebase;
- PostgreSQL remoto;
- MongoDB remoto;
- navegador;
- API paga;
- API gratuita;
- login online;
- Docker;
- OpenAI;
- Gemini;
- Claude;
- LLM;
- internet.

Se o computador estiver totalmente sem conexão, o Organiza deve continuar funcionando normalmente.

---

# 5. STACK TÉCNICA

Utilize preferencialmente:

## Interface

- Flutter
- Dart

## Banco

- SQLite

## Persistência

- Drift

## Arquitetura

Separar claramente:

```text
lib/
├── core/
├── database/
├── data/
├── domain/
├── application/
├── presentation/
└── services/
```

Fluxo:

```text
UI
↓
Controller / ViewModel
↓
Use Case
↓
Repository
↓
DAO
↓
SQLite
```

Widgets não devem executar SQL diretamente.

Regras de negócio não devem ficar espalhadas dentro da interface.

---

# 6. PORTABILIDADE

Primeira versão:

**Windows**

Arquitetura futura:

```text
Windows
↓
Android
↓
iOS
```

Evite dependências exclusivas do Windows quando houver alternativas multiplataforma.

Recursos específicos do sistema operacional devem ser isolados atrás de interfaces.

Exemplo:

```text
NotificationService
BackupService
FileService
SecureStorageService
WindowService
```

---

# 7. DIREÇÃO VISUAL — PROIBIDO "AI SLOP"

A interface NÃO deve parecer um site ou aplicativo genérico gerado por IA.

Evitar:

- glassmorphism;
- blur exagerado;
- fundos com gradiente roxo e azul;
- glow neon;
- cards transparentes;
- sombras exageradas;
- bordas brilhantes;
- ícones gigantes;
- emojis como elemento principal;
- dezenas de cards arredondados;
- frases motivacionais artificiais;
- gráficos decorativos;
- animações sem função;
- aparência de landing page SaaS;
- layout de template genérico.

O Organiza deve parecer um **software desktop real**.

Referências apenas de filosofia visual:

- Linear;
- Raycast;
- Notion;
- ferramentas financeiras desktop modernas.

Não copiar nenhum produto.

---

# 8. IDENTIDADE VISUAL

Criar uma identidade própria.

Características:

- limpa;
- sóbria;
- compacta;
- organizada;
- moderna;
- profissional;
- funcional.

Priorizar:

- hierarquia;
- alinhamento;
- tipografia;
- contraste;
- espaçamento;
- densidade adequada.

---

# 9. CORES

Implementar:

- tema claro;
- tema escuro;
- tema do sistema.

## Tema escuro

Usar principalmente:

- preto;
- grafite;
- cinza escuro;
- cinza médio;
- branco.

## Tema claro

Usar:

- branco;
- cinza muito claro;
- grafite.

Estados financeiros:

- receita: verde;
- despesa: vermelho;
- alerta: laranja;
- atenção: amarelo;
- informação: azul discreto.

Não usar cores saturadas em excesso.

---

# 10. TIPOGRAFIA

Utilizar uma fonte moderna e legível.

Possíveis referências:

- Inter;
- Geist;
- IBM Plex Sans;
- Source Sans.

Criar uma hierarquia coerente para:

- título;
- subtítulo;
- seção;
- texto;
- legenda;
- valor financeiro.

---

# 11. DENSIDADE DESKTOP

O Organiza será primeiro um aplicativo desktop.

A interface deve aproveitar bem resoluções como:

- 1366x768;
- 1920x1080;
- 2560x1440.

Não transformar todas as informações em blocos gigantes projetados apenas para celular.

Ao mesmo tempo, manter a estrutura responsiva.

---

# 12. NAVEGAÇÃO PRINCIPAL

Sidebar sugerida:

```text
ORGANIZA

Visão geral

FINANÇAS
Finanças
Contas
Cartões
Orçamentos
Investimentos

ORGANIZAÇÃO
Planejamento
Metas

ANÁLISE
Relatórios

Configurações
```

A sidebar deve:

- ser compacta;
- poder ser recolhida;
- manter estado;
- funcionar corretamente com teclado.

---

# 13. BARRA SUPERIOR

A barra superior deve poder mostrar:

- título da tela;
- busca;
- ocultar valores;
- tema;
- menu local.

Sem hero section.

Sem slogans gigantes.

Sem aparência de landing page.

---

# 14. BUSCA GLOBAL

Criar busca local.

Atalho:

```text
Ctrl + K
```

Pesquisar:

- transações;
- contas;
- cartões;
- tarefas;
- metas;
- investimentos.

Resultados agrupados por tipo.

A busca deve ser rápida mesmo com grande quantidade de dados.

---

# 15. VISÃO GERAL

A home deve responder:

**Como está minha situação hoje?**

Mostrar apenas informações importantes.

Estrutura sugerida:

```text
Saldo atual
Entradas do mês
Saídas do mês
Disponível para gastar

Contas próximas

Últimas transações

Tarefas de hoje

Orçamento

Investimentos
```

Evitar excesso de widgets.

---

# 16. RESUMO FINANCEIRO

Mostrar:

## Saldo Atual

Soma dos saldos das contas consideradas no cálculo.

## Entradas do mês

Receitas do período.

## Saídas do mês

Despesas do período.

## Disponível para gastar

Regra inicial:

```text
Saldo atual
-
despesas pendentes relevantes do período
=
disponível para gastar
```

Documentar a regra precisamente.

---

# 17. OCULTAR VALORES

Criar controle global:

**Ocultar valores**

Quando ativo:

```text
R$ ••••••
```

Aplicar em:

- saldo;
- receitas;
- despesas;
- cartões;
- investimentos;
- metas financeiras.

Persistir a preferência localmente.

---

# 18. NOVA TRANSAÇÃO

Atalho:

```text
Ctrl + N
```

Tipos:

- Despesa;
- Receita;
- Transferência.

Campos:

- tipo;
- descrição;
- valor;
- categoria;
- conta;
- cartão;
- data;
- status;
- observações;
- tags.

Status:

- Pago;
- Pendente.

O campo de valor deve receber foco rapidamente.

---

# 19. VALORES MONETÁRIOS

Nunca armazenar dinheiro como `float` ou `double`.

Armazenar em centavos inteiros.

Exemplo:

```text
R$ 25,90
=
2590
```

---

# 20. TRANSFERÊNCIAS

Transferências movimentam dinheiro entre contas.

Não devem ser contabilizadas como receita ou despesa.

A operação deve ser atômica.

```text
Conta A
↓
Conta B
```

Se uma etapa falhar, nenhuma alteração deve ser confirmada.

---

# 21. TRANSAÇÕES RECORRENTES

Permitir recorrências:

- semanal;
- mensal;
- bimestral;
- trimestral;
- semestral;
- anual;
- personalizada.

Exemplos:

- aluguel;
- internet;
- faculdade;
- streaming;
- salário.

Permitir:

- editar somente esta ocorrência;
- editar esta e próximas;
- encerrar recorrência.

Nunca gerar duplicações acidentais.

---

# 22. TRANSAÇÕES — LISTA

Colunas possíveis:

- data;
- descrição;
- categoria;
- conta;
- status;
- valor.

Permitir filtros:

- período;
- conta;
- cartão;
- categoria;
- tipo;
- status;
- valor;
- texto.

Permitir ordenação.

---

# 23. CONTAS

Tipos:

- carteira;
- conta corrente;
- conta digital;
- poupança;
- dinheiro;
- outro.

Campos:

- nome;
- instituição;
- tipo;
- saldo inicial;
- cor;
- ícone;
- status.

Permitir arquivamento.

---

# 24. CARTÕES DE CRÉDITO

Cadastrar:

- nome;
- banco;
- limite;
- dia de fechamento;
- dia de vencimento;
- cor;
- últimos 4 dígitos opcionais.

Nunca armazenar:

- número completo;
- CVV;
- senha.

Mostrar:

- limite utilizado;
- limite disponível;
- fatura atual;
- próxima fatura.

---

# 25. FATURAS

Estados:

- aberta;
- fechada;
- paga.

Calcular corretamente a fatura com base em:

- data da compra;
- fechamento;
- vencimento.

Criar testes específicos para essa regra.

---

# 26. PAGAMENTO DE FATURA

Ao pagar:

- associar o pagamento a uma conta;
- atualizar o estado da fatura;
- manter histórico;
- evitar contabilização dupla;
- executar em transação do banco.

---

# 27. CATEGORIAS

Categorias iniciais:

- Alimentação;
- Moradia;
- Transporte;
- Educação;
- Saúde;
- Lazer;
- Assinaturas;
- Compras;
- Contas;
- Investimentos;
- Salário;
- Outros.

Permitir:

- criar;
- editar;
- arquivar.

Categorias com histórico não devem ser apagadas de forma destrutiva.

---

# 28. ORÇAMENTOS

Permitir limite mensal por categoria.

Exemplo:

```text
Alimentação
R$ 800
```

Mostrar:

```text
R$ 540 utilizados
R$ 260 restantes
67,5%
```

Estados:

- abaixo de 70%: normal;
- 70% a 90%: atenção;
- acima de 90%: alerta;
- acima de 100%: excedido.

Não depender somente de cor.

---

# 29. METAS FINANCEIRAS

Exemplos:

- reserva de emergência;
- computador;
- viagem;
- curso.

Campos:

- nome;
- valor alvo;
- valor acumulado;
- prazo;
- descrição.

Mostrar progresso.

---

# 30. INVESTIMENTOS

Registrar manualmente:

- nome;
- tipo;
- quantidade;
- preço médio;
- valor investido;
- valor atual;
- instituição;
- data;
- observação.

Tipos:

- reserva;
- renda fixa;
- ações;
- fundos;
- FIIs;
- criptomoedas;
- outros.

Não depender de APIs de preço.

---

# 31. PLANEJAMENTO

Implementar sistema de tarefas.

Uma tarefa deve possuir:

- título;
- descrição;
- data;
- horário opcional;
- prioridade;
- categoria;
- status;
- recorrência opcional.

Status:

- Pendente;
- Em andamento;
- Concluída.

Prioridade:

- Baixa;
- Normal;
- Alta.

---

# 32. TAREFAS RECORRENTES

Permitir:

- diária;
- semanal;
- mensal;
- personalizada.

Isso NÃO deve se transformar em sistema de hábitos.

Não criar streak.

Não criar gamificação.

---

# 33. TELA HOJE

Mostrar:

- tarefas de hoje;
- contas vencendo;
- faturas próximas;
- resumo financeiro;
- meta de água.

A tela deve ser prática e objetiva.

---

# 34. HIDRATAÇÃO

Manter como ferramenta simples.

Meta configurável.

Padrão:

```text
2 L
```

Atalhos:

```text
+250 ml
-250 ml
Zerar
```

Mostrar:

```text
1,25 L / 2 L
```

Sem:

- streak;
- medalha;
- XP;
- gamificação.

---

# 35. METAS PESSOAIS

Exemplos:

- concluir projeto;
- terminar faculdade;
- aprender italiano;
- ler determinado livro.

Campos:

- nome;
- descrição;
- prazo;
- progresso;
- etapas.

---

# 36. RELATÓRIOS

Criar relatórios realmente úteis.

## Gastos por categoria

Gráfico de donut simples.

## Entradas x Saídas

Gráfico de barras.

Padrão:

últimos 6 meses.

## Evolução do saldo

Linha simples opcional.

Não criar gráficos apenas para decorar.

---

# 37. INSIGHTS LOCAIS

Gerar apenas com:

- SQL;
- regras;
- comparações;
- estatística simples.

Exemplos:

```text
Você gastou 15% mais com alimentação que no mês anterior.
```

```text
Sua fatura vence em 3 dias.
```

```text
O orçamento de lazer atingiu 92%.
```

```text
Existem 4 contas pendentes neste mês.
```

SEM IA.

---

# 38. TEXTO DA INTERFACE

Evitar linguagem artificial.

RUIM:

```text
Transforme sua jornada financeira.
```

BOM:

```text
Resumo financeiro
```

RUIM:

```text
Dê o próximo passo rumo aos seus sonhos.
```

BOM:

```text
Metas
```

RUIM:

```text
Veja como sua vida está evoluindo.
```

BOM:

```text
Relatórios
```

O software deve informar, não tentar motivar artificialmente.

---

# 39. ONBOARDING

Primeira execução:

```text
Bem-vindo ao Organiza
```

Etapas:

- nome;
- moeda;
- tema;
- primeira conta.

Permitir pular etapas opcionais.

Não criar onboarding longo.

---

# 40. CONFIGURAÇÕES

Áreas:

- Geral;
- Aparência;
- Finanças;
- Notificações;
- Dados;
- Segurança;
- Sobre.

Configuração inicial:

```text
Moeda: BRL
Símbolo: R$
Data: dd/MM/yyyy
```

Preparar internacionalização.

---

# 41. BANCO DE DADOS

Utilizar SQLite.

Tabelas aproximadas:

```text
settings

accounts
categories
transactions
recurrences

credit_cards
card_invoices

budgets
financial_goals

investments

tasks
personal_goals
goal_steps

water_entries

notifications

tags
transaction_tags
```

Não criar tabelas de hábitos.

---

# 42. IDENTIFICADORES

Preferir UUIDs para entidades principais.

Campos comuns:

```text
id
createdAt
updatedAt
```

Preparar futura sincronização, sem implementá-la agora.

---

# 43. MIGRAÇÕES

Criar versionamento do schema.

```text
schemaVersion
```

Toda alteração no banco deve possuir migração.

Nunca exigir exclusão do banco do usuário para atualizar o aplicativo.

Criar testes de migração.

---

# 44. BACKUP

Criar:

- exportar backup;
- importar backup.

Formato sugerido:

```text
.organiza
```

Pode conter:

- banco;
- versão;
- metadados.

Também oferecer JSON quando apropriado.

---

# 45. RESTAURAÇÃO

Antes de restaurar:

1. validar arquivo;
2. validar versão;
3. validar integridade;
4. gerar backup do estado atual;
5. pedir confirmação;
6. restaurar;
7. verificar integridade após restauração.

Nunca sobrescrever silenciosamente.

---

# 46. CSV

Permitir exportação de transações.

Preparar importador de CSV com pré-visualização.

Exemplo:

```text
120 registros encontrados
117 válidos
3 precisam de revisão
```

---

# 47. PRIVACIDADE

Nenhum dado pessoal deve sair do computador na versão inicial.

Não adicionar:

- analytics;
- trackers;
- publicidade;
- telemetria externa;
- pixels.

---

# 48. SEGURANÇA

Não armazenar:

- senha bancária;
- CVV;
- número completo de cartão;
- tokens bancários desnecessários.

Evitar dados financeiros completos em logs.

Não implementar criptografia caseira.

Preparar arquitetura para solução madura futura, como SQLCipher, se necessário.

---

# 49. VALIDAÇÕES

Validar:

- valores;
- datas;
- campos obrigatórios;
- contas;
- cartões;
- limites;
- recorrências;
- relacionamentos.

Nunca permitir:

- NaN;
- Infinity;
- datas impossíveis;
- valores monetários inválidos.

---

# 50. TRATAMENTO DE ERROS

Nunca mostrar stack trace diretamente ao usuário.

Mensagem exemplo:

```text
Não foi possível salvar a transação.
Nenhum dado anterior foi alterado.
```

Os logs técnicos devem ajudar no diagnóstico sem expor dados pessoais desnecessários.

---

# 51. PERFORMANCE

Não carregar o banco inteiro na memória.

Utilizar:

- índices;
- paginação;
- consultas específicas;
- lazy loading;
- rebuilds controlados.

Testar com no mínimo:

- 10.000 transações;
- 1.000 tarefas.

---

# 52. RESPONSIVIDADE

Criar breakpoints conceituais:

```text
Compact
Medium
Expanded
```

Expanded:

- desktop.

Compact:

- futura versão mobile.

Não criar duas aplicações completamente separadas.

---

# 53. ACESSIBILIDADE

Implementar:

- contraste adequado;
- foco visível;
- suporte a teclado;
- labels;
- tooltips;
- áreas clicáveis adequadas;
- suporte razoável a escala de texto.

Cor nunca deve ser o único indicador de estado.

---

# 54. ATALHOS WINDOWS

```text
Ctrl + K        → Busca
Ctrl + N        → Nova transação
Ctrl + Shift + N → Nova tarefa
Ctrl + ,        → Configurações
Esc             → Fechar modal
```

---

# 55. NOTIFICAÇÕES LOCAIS

Permitir notificações opcionais:

- conta vencendo;
- fatura vencendo;
- tarefa;
- meta de água.

Sem internet.

---

# 56. DESIGN SYSTEM

Centralizar tokens:

```text
spacing
radius
typography
colors
borders
elevation
```

Evitar números visuais aleatórios espalhados pelo projeto.

---

# 57. QUALIDADE VISUAL

Antes de considerar uma tela pronta, verificar:

- parece um aplicativo real?
- é fácil encontrar o que importa?
- há informação redundante?
- há espaço desperdiçado?
- há cards demais?
- há cores demais?
- há texto promocional artificial?
- funciona bem com mouse?
- funciona bem com teclado?
- parece template de IA?

Se parecer uma landing page SaaS ou dashboard genérico gerado por IA:

**redesenhe antes de considerar pronta.**

---

# 58. GITHUB

Preparar o projeto para portfólio.

Incluir:

```text
README.md
.gitignore
docs/
test/
integration_test/
```

Nunca versionar:

- banco pessoal;
- backups reais;
- logs pessoais;
- secrets;
- chaves;
- dados financeiros reais.

---

# 59. README

Criar README profissional.

Estrutura:

```text
Organiza

Descrição
Funcionalidades
Tecnologias
Arquitetura
Instalação
Desenvolvimento
Testes
Build Windows
Estrutura
Privacidade
Roadmap
```

Sem dezenas de emojis.

Sem marketing artificial.

Caso o projeto seja publicado como portfólio, deixar claro que ferramentas de IA auxiliaram no desenvolvimento.

---

# 60. DOCUMENTAÇÃO TÉCNICA OBRIGATÓRIA

Criar:

```text
docs/architecture.md
docs/financial_rules.md
docs/testing_strategy.md
docs/known_good_state.md
docs/error_knowledge_base.md
docs/change_log.md
```

Esses arquivos fazem parte do processo de desenvolvimento.

---

# 61. `docs/financial_rules.md`

Documentar:

- saldo;
- receita;
- despesa;
- transferência;
- cartão;
- fechamento;
- vencimento;
- pagamento de fatura;
- recorrência;
- orçamento;
- disponível para gastar.

---

# 62. `docs/known_good_state.md`

Este arquivo é obrigatório.

Ele representa a **baseline conhecida como funcional**.

Depois de cada ciclo completo aprovado, registrar:

```text
Data/hora
Versão/commit
Módulos validados
Fluxos testados
Testes que passaram
Build validado
Limitações conhecidas
```

Exemplo:

```markdown
## Baseline 2026-09-09

Commit: abc123

Funcionando:
- criação de contas
- criação de receita
- criação de despesa
- transferência entre contas
- persistência após reinicialização

Testes:
- 42 unitários aprovados
- 6 integração aprovados

Não quebrar:
- cálculo do saldo
- atomicidade das transferências
```

Antes de qualquer nova alteração, leia este arquivo.

O comportamento listado como funcional deve ser tratado como **contrato de regressão**.

---

# 63. `docs/error_knowledge_base.md`

Este arquivo funciona como uma memória técnica local do projeto.

Sempre que ocorrer um erro real, registrar:

```text
ID do erro
Data
Sintoma
Como reproduzir
Causa raiz
Correção aplicada
Arquivos afetados
Teste criado
Como impedir regressão
```

Exemplo:

```markdown
## ERR-014 — Fatura duplicada após reiniciar

Sintoma:
Uma compra recorrente era adicionada duas vezes.

Causa:
O gerador não verificava occurrenceId antes de inserir.

Correção:
Criado índice único e verificação idempotente.

Teste:
recurrence_does_not_duplicate_existing_occurrence

Regressão:
Nunca remover a constraint sem substituir por mecanismo equivalente.
```

Não repetir um erro já conhecido.

Antes de corrigir um erro novo, procurar neste arquivo por casos semelhantes.

---

# 64. `docs/change_log.md`

Registrar mudanças relevantes.

Cada alteração deve informar:

```text
Objetivo
Arquivos modificados
Comportamento anterior
Comportamento novo
Testes adicionados/alterados
Riscos de regressão
Resultado final
```

---

# 65. LOOP OBRIGATÓRIO DE DESENVOLVIMENTO

Toda alteração deve seguir este ciclo:

```text
ENTENDER
↓
MAPEAR O ESTADO ATUAL
↓
ALTERAR
↓
TESTAR
↓
ENCONTRAR ERROS
↓
DIAGNOSTICAR CAUSA RAIZ
↓
CORRIGIR
↓
CRIAR TESTE DE REGRESSÃO
↓
TESTAR NOVAMENTE
↓
RODAR REGRESSÃO GLOBAL
↓
COMPARAR COM BASELINE
↓
ATUALIZAR MEMÓRIA TÉCNICA
↓
APROVAR
```

Esse processo é obrigatório.

---

# 66. LOOP DE TESTE E APRENDIZADO

Quando um teste falhar:

## Passo 1 — NÃO aplicar correções aleatórias

Primeiro determinar:

- qual comportamento deveria acontecer;
- qual comportamento aconteceu;
- em qual camada ocorreu;
- qual alteração recente pode ter causado o problema.

## Passo 2 — Reproduzir

Criar uma reprodução mínima do erro.

## Passo 3 — Identificar causa raiz

Não corrigir apenas o sintoma.

## Passo 4 — Corrigir

Aplicar a menor correção coerente com a arquitetura.

## Passo 5 — Criar teste

Todo bug relevante corrigido deve ganhar um teste que falharia antes da correção.

## Passo 6 — Rodar teste específico

Confirmar que a correção funciona.

## Passo 7 — Rodar testes relacionados

Testar módulos dependentes.

## Passo 8 — Rodar regressão

Executar a suíte completa apropriada.

## Passo 9 — Comparar com o estado conhecido como bom

Ler:

```text
docs/known_good_state.md
```

Confirmar que funcionalidades anteriormente aprovadas continuam funcionando.

## Passo 10 — Registrar aprendizado

Atualizar:

```text
docs/error_knowledge_base.md
```

Registrar:

- o erro;
- a causa;
- a correção;
- o teste;
- a prevenção.

Este é o mecanismo de "aprendizado" do projeto.

O aprendizado deve ficar salvo no repositório e não depender da memória temporária da IA.

---

# 67. REGRA DE NÃO REGRESSÃO

Uma nova funcionalidade NÃO pode ser considerada pronta se quebrar algo que já estava funcionando.

Antes de finalizar qualquer requisição:

1. consulte a baseline;
2. identifique os fluxos afetados;
3. rode os testes antigos relacionados;
4. execute os testes novos;
5. execute regressão global adequada;
6. confirme que os contratos anteriores continuam válidos.

Se algum comportamento anterior quebrar:

**a tarefa ainda não terminou.**

---

# 68. MATRIZ DE FUNCIONALIDADES

Criar:

```text
docs/feature_matrix.md
```

Formato sugerido:

| Funcionalidade | Implementada | Testada | Integração | Regressão | Última validação |
|---|---:|---:|---:|---:|---|
| Criar conta | Sim | Sim | Sim | Sim | data |
| Receita | Sim | Sim | Sim | Sim | data |
| Transferência | Sim | Sim | Sim | Sim | data |
| Faturas | Em andamento | Parcial | Não | Não | data |

Antes de uma nova requisição, consultar essa matriz.

Nunca assumir que algo funciona apenas porque existe código.

---

# 69. TESTES

Criar:

```text
test/
integration_test/
```

Cobertura prioritária:

- saldo;
- receitas;
- despesas;
- transferências;
- cartões;
- faturas;
- fechamento;
- vencimento;
- recorrências;
- orçamento;
- disponível para gastar;
- tarefas;
- hidratação;
- backup;
- restauração;
- migrações.

---

# 70. PIRÂMIDE DE TESTES

Priorizar:

## Testes unitários

Regras puras.

## Testes de banco

DAOs, constraints, migrações e transações.

## Testes de widget

Estados importantes da interface.

## Testes de integração

Fluxos de usuário completos.

Não depender exclusivamente de testes de interface.

---

# 71. TESTE DE REGRESSÃO POR MÓDULO

Ao modificar um módulo, testar também os módulos conectados.

Exemplos:

## Mudou transações

Testar:

- saldo;
- dashboard;
- orçamento;
- relatórios;
- contas;
- recorrências.

## Mudou cartões

Testar:

- compras;
- faturas;
- pagamento;
- limite;
- dashboard.

## Mudou banco

Testar:

- migrações;
- persistência;
- backup;
- restauração;
- DAOs principais.

---

# 72. TESTE DE FLUXO COMPLETO

Fluxo mínimo obrigatório:

```text
Abrir Organiza
↓
Criar conta
↓
Criar receita
↓
Criar despesa
↓
Criar segunda conta
↓
Realizar transferência
↓
Criar cartão
↓
Registrar compra
↓
Verificar fatura
↓
Pagar fatura
↓
Criar orçamento
↓
Criar tarefa
↓
Criar meta
↓
Criar investimento
↓
Registrar água
↓
Fechar completamente o aplicativo
↓
Abrir novamente
↓
Validar persistência
```

---

# 73. TESTE DE PRIMEIRO USO

Testar com banco completamente vazio.

Nenhuma tela pode quebrar por:

- lista vazia;
- `null`;
- ausência de conta;
- ausência de cartão;
- ausência de transações;
- ausência de investimentos;
- ausência de tarefas.

---

# 74. TESTE DE REINICIALIZAÇÃO

Após cadastrar dados:

1. fechar o aplicativo;
2. encerrar completamente o processo;
3. abrir novamente;
4. confirmar persistência.

Validar:

- contas;
- transações;
- cartões;
- faturas;
- orçamentos;
- tarefas;
- metas;
- investimentos;
- hidratação;
- configurações.

---

# 75. TESTE DE VOLUME

Gerar dados fictícios:

```text
10.000 transações
1.000 tarefas
centenas de registros auxiliares
```

Verificar:

- tempo de abertura;
- filtros;
- busca;
- paginação;
- relatórios;
- consumo de memória.

---

# 76. COMANDOS DE VALIDAÇÃO

Ao concluir um ciclo relevante, executar quando aplicável:

```bash
dart format --set-exit-if-changed .
flutter analyze
flutter test
flutter test integration_test
flutter build windows --release
```

Caso existam ferramentas adicionais aprovadas no projeto, documentá-las em:

```text
docs/testing_strategy.md
```

---

# 77. REGRA DE BUILD

Não afirmar:

```text
Build concluído
```

sem executar de fato o build.

Não afirmar:

```text
Todos os testes passaram
```

sem executar a suíte correspondente.

Se algo não puder ser executado, declarar explicitamente.

---

# 78. CHECKPOINT AUTOMÁTICO APÓS CADA CICLO

Ao final de cada ciclo bem-sucedido:

1. atualizar `feature_matrix.md`;
2. atualizar `known_good_state.md`;
3. atualizar `change_log.md`;
4. atualizar `error_knowledge_base.md` caso tenha ocorrido bug;
5. executar regressão;
6. salvar o estado estável.

Somente depois disso iniciar uma nova grande alteração.

---

# 79. REGRA PARA PRÓXIMAS REQUISIÇÕES

Sempre que o usuário pedir uma nova mudança no futuro:

## Antes de editar

Leia:

```text
ORGANIZA_MEGA_PROMPT.md
docs/known_good_state.md
docs/feature_matrix.md
docs/error_knowledge_base.md
docs/change_log.md
```

## Depois

Mapeie:

- quais módulos serão alterados;
- quais módulos dependem deles;
- quais testes precisam continuar passando.

## Só então

Implemente a alteração.

---

# 80. PROIBIDO "CORRIGIR" REMOVENDO FUNCIONALIDADES

Se uma implementação causar erro:

NÃO faça isso:

- remover o recurso;
- esconder o botão;
- comentar o código;
- substituir por mock;
- retornar valor falso;
- ignorar exceção;
- desativar teste;
- apagar teste que falhou.

Investigue e corrija a causa.

---

# 81. PROIBIDO FAZER TESTE PASSAR ARTIFICIALMENTE

Nunca:

- alterar expectativa correta somente para fazer teste passar;
- ignorar teste;
- marcar teste como skip sem justificativa;
- capturar exceção e fingir sucesso;
- remover assertion importante.

Se um teste está correto e falha, corrija o software.

---

# 82. PROTEÇÃO DE FUNCIONALIDADES APROVADAS

Quando uma funcionalidade atingir estado estável:

1. criar testes;
2. documentar comportamento;
3. adicionar à baseline;
4. adicionar à matriz;
5. tratá-la como contrato.

Mudanças futuras podem alterar esse comportamento apenas se a nova solicitação exigir explicitamente isso.

---

# 83. AUTOAUDITORIA

Depois de cada módulo, perguntar:

```text
Existe botão sem função?
Algum dado não persiste?
Existe cálculo incorreto?
Existe duplicação?
Há risco de perda de dados?
Existe regressão?
A interface parece artificial?
Há cards demais?
Há componente desnecessário?
Alguma função depende de internet?
O app continua rápido?
Os testes anteriores continuam passando?
```

Corrigir antes de avançar.

---

# 84. QUALIDADE DO CÓDIGO

Não deixar em funcionalidades concluídas:

```text
TODO
FIXME
placeholder
botão sem ação
função vazia
mock permanente
dados hardcoded
```

Mocks são permitidos apenas em testes ou durante desenvolvimento temporário.

---

# 85. DOCUMENTAÇÃO DO CÓDIGO

Comentários devem explicar principalmente:

**por que determinada decisão existe.**

Documentar especialmente:

- cálculos financeiros;
- recorrências;
- regras de fatura;
- migrações;
- backup;
- transações atômicas;
- decisões arquiteturais.

---

# 86. INTEGRAÇÃO FUTURA COM EDITALOS

Preparar apenas arquitetura de importação.

Não criar dependência obrigatória.

Exemplo:

```text
importers/
└── editalos_importer.dart
```

Dados futuros possíveis:

- concurso;
- cargo;
- matéria;
- assunto;
- prazo;
- prova.

Esses dados poderão virar tarefas ou planejamento.

Não implementar a integração completa agora.

---

# 87. NÃO IMPLEMENTAR IA DENTRO DO ORGANIZA

Regra absoluta:

Não utilizar dentro do produto:

- LLM;
- machine learning;
- modelos locais;
- OpenAI;
- Gemini;
- Claude;
- embeddings.

O fato de uma IA ajudar a desenvolver o código NÃO significa que o aplicativo deve possuir IA.

---

# 88. ORDEM DE IMPLEMENTAÇÃO

Ordem sugerida:

```text
1. Estrutura Flutter
2. Arquitetura
3. Design System
4. SQLite + Drift
5. Sistema de testes
6. Baseline e arquivos de memória técnica
7. Configurações
8. Contas
9. Categorias
10. Transações
11. Transferências
12. Dashboard financeiro
13. Cartões
14. Faturas
15. Recorrências
16. Orçamentos
17. Metas financeiras
18. Investimentos
19. Tarefas
20. Planejamento
21. Metas pessoais
22. Hidratação
23. Relatórios
24. Busca
25. Backup
26. Importação/exportação
27. Notificações
28. Onboarding
29. Testes completos
30. Testes de regressão
31. Polimento
32. Build Windows
```

---

# 89. ESTRUTURA FINAL ESPERADA

```text
Organiza/
├── lib/
│   ├── core/
│   ├── database/
│   ├── data/
│   ├── domain/
│   ├── application/
│   ├── presentation/
│   └── services/
│
├── assets/
│
├── docs/
│   ├── architecture.md
│   ├── financial_rules.md
│   ├── testing_strategy.md
│   ├── feature_matrix.md
│   ├── known_good_state.md
│   ├── error_knowledge_base.md
│   └── change_log.md
│
├── test/
├── integration_test/
├── windows/
├── android/
├── ios/
├── pubspec.yaml
├── README.md
├── .gitignore
└── ORGANIZA_MEGA_PROMPT.md
```

---

# 90. ROADMAP

Arquitetura preparada para:

```text
Organiza Windows
↓
Organiza Android
↓
Organiza iOS
↓
Sincronização opcional futura
↓
Integração opcional com EditalOS
```

Prioridade atual:

```text
WINDOWS
LOCAL
OFFLINE
SEM IA
SEM HÁBITOS
SEM SERVIDOR
SEM ASSINATURA
```

---

# 91. RESULTADO ESPERADO

O aplicativo deve conseguir:

```text
receber dados
↓
validar
↓
salvar no SQLite
↓
consultar
↓
calcular
↓
mostrar
↓
editar
↓
arquivar
↓
exportar
↓
fazer backup
↓
restaurar
```

com consistência.

---

# 92. CONTRATO FINAL DE EXECUÇÃO

Agora construa o Organiza.

Não entregue apenas arquitetura ou explicações.

Crie o projeto real.

Implemente:

- banco;
- telas;
- regras;
- persistência;
- validação;
- testes;
- backup;
- documentação;
- build Windows.

Para cada erro encontrado:

```text
REPRODUZIR
↓
DIAGNOSTICAR
↓
CORRIGIR
↓
CRIAR TESTE
↓
RODAR TESTE
↓
RODAR REGRESSÃO
↓
REGISTRAR APRENDIZADO
```

Antes de cada nova requisição:

```text
LER BASELINE
↓
IDENTIFICAR O QUE FUNCIONA
↓
PRESERVAR CONTRATOS
↓
IMPLEMENTAR MUDANÇA
↓
TESTAR
↓
VALIDAR REGRESSÃO
↓
ATUALIZAR BASELINE
```

Nunca quebre silenciosamente uma funcionalidade anteriormente validada.

Nunca esconda um erro para continuar.

Nunca remova testes corretos para conseguir aprovação.

Nunca diga que algo foi testado sem realmente testar.

O aprendizado sobre erros deve ser persistido nos arquivos do próprio projeto para que futuras IAs e futuras sessões possam entender:

- o que deu errado;
- por que deu errado;
- como foi corrigido;
- como evitar a regressão.

O Organiza deve evoluir de forma incremental, mantendo sempre um estado conhecido como funcional.

Esse princípio é tão importante quanto a implementação das próprias funcionalidades.
