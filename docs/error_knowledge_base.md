# Base de conhecimento de erros

## ERR-001 — Flex em altura ilimitada no dashboard

**Data:** 2026-09-10

**Sintoma:** teste de integração falhava com `RenderFlex children have non-zero flex but incoming height constraints are unbounded`.

**Causa raiz:** um `Spacer` vertical estava dentro de um painel inserido em `ListView` sem altura fixa no layout compacto.

**Correção:** substituição do espaço flexível por espaçamento explícito e teste de integração com `tester.takeException()`.

**Regressão:** manter a verificação de renderização do dashboard em 1366×768.

## ERR-002 — Overflow no resumo de cartão

**Data:** 2026-09-10

**Sintoma:** a tela de Cartões excedia a altura do painel em 25 pixels.

**Causa raiz:** métricas, barra de limite e aviso ocupavam mais que os 300 pixels reservados.

**Correção:** altura funcional ajustada e caminho compacto com altura explícita apenas no cartão visual.

**Regressão:** o fluxo de integração navega para Cartões e falha se houver exceção de layout.

## ERR-003 — Screenshot nativo indisponível no integration_test Windows

**Data:** 2026-09-10

**Sintoma:** `MissingPluginException` ao chamar `captureScreenshot`.

**Causa raiz:** o canal nativo de captura não possuía implementação no runner Windows.

**Correção:** captura direta do `RenderRepaintBoundary`, sem depender do plugin nativo.

**Regressão:** as imagens de QA continuam sendo geradas em `build/qa/` pelo teste de integração.

## ERR-004 — Overflow após refinamento visual do ciclo do cartão

**Data:** 2026-09-10

**Sintoma:** o fluxo de integração detectava `RenderFlex overflowed by 2.0 pixels on the bottom` ao abrir Cartões em 1366×768.

**Causa raiz:** o novo espaçamento interno de 20 pixels deixou o painel de ciclo ligeiramente maior que a altura fixa compartilhada com o cartão visual.

**Correção:** a altura da linha desktop passou a acomodar o conteúdo refinado, sem reduzir legibilidade nem ocultar elementos.

**Regressão:** manter `tester.takeException()` após a navegação para Cartões e revisar a captura gerada em 1366×768.

## ERR-005 — Flex sem altura definida no gráfico de Relatórios

**Data:** 2026-09-11

**Sintoma:** ao abrir Relatórios, o teste integrado falhava com `RenderFlex children have non-zero flex but incoming height constraints are unbounded`.

**Causa raiz:** as colunas do gráfico de barras usavam `Expanded` dentro de um painel cuja área de gráfico não possuía altura explícita.

**Correção:** a área do gráfico passou a ter altura fixa dentro do painel; os `Expanded` agora recebem limite vertical válido.

**Regressão:** o teste integrado navega por Relatórios em 1366×768 e verifica exceções de renderização.

Para os próximos erros, use este formato:

```markdown
## ERR-001 — título curto

Data:
Sintoma:
Como reproduzir:
Causa raiz:
Correção aplicada:
Arquivos afetados:
Teste criado:
Como impedir regressão:
```

Antes de corrigir um problema, pesquise aqui por sintomas ou módulos semelhantes. Não esconda erros removendo funcionalidade ou desativando testes.
