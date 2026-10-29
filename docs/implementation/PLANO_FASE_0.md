# Plano de implementação — Fundação V3

Contrato: `../product/ORGANIZA_MEGA_PROMPT_V3.md`, Fase 0. Este plano detalha a execução já solicitada; não substitui as fases seguintes.

## Arquitetura preservada

Flutter/SQLite direto e fachada ChangeNotifier. A UI recebe o mesmo Clock do store; componentes sem store recebem Clock ou uma data de referência explícita. Nenhuma mudança de schema, cálculo financeiro ou identidade visual nesta fase.

## Tarefas e verificação

1. Preservar fonte original em branch local e executar pub get/analyze/test antes de código: concluído (108 testes).
2. Criar regressões congelando datas de negócio em telas e formulário; observá-las falhar contra o código original. Propagar Clock aos seletores e componentes e atualizar todos os chamadores. Provar que não há DateTime.now em presentation e que testes/goldens permanecem verdes.
3. Criar fixture determinística de pelo menos 10 mil transações e testes de referência, integridade, centavos e repetibilidade; observar RED antes da implementação. Não usar banco real do usuário.
4. Configurar CI Windows e Ubuntu, Dependabot semanal e lints incrementais. Builds manuais separados, sem assinatura oficial. Não publicar artefatos de debug como release.
5. Atualizar README/estado conhecido/matriz/dossiê com as divergências encontradas e resultados reais. Separar validação local de execução remota.
6. Executar flutter analyze, flutter test --coverage e integração Windows; revisar a alteração com outro agente. Comitar tarefas em português.

## Limites de aceite

O contrato exige CI verde no PR antes da Fase 1. O dono do produto indicou danielcdesk/Organiza como destino. O main remoto foi conferido contra o ZIP. As mudanças serão enviadas em branch/PR de revisão; não declarar CI remoto aprovado nem pular esse requisito antes da execução.

## Revisão

Verificar referências temporais em fechamento/vencimento de cartão, compatibilidade dos chamadores de diálogos, isolamento dos testes da base instalada, cobertura dos dados de massa e ausência de chaves em workflows. Goldens existentes não devem ser regenerados apenas para esconder falhas.
