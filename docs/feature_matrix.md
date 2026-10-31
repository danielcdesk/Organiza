# Matriz de funcionalidades

## Verificação V3 — 29/10/2026

Após a Fase 0: análise limpa, 116 testes aprovados com cobertura de linhas 67,10%, 2 fluxos Windows aprovados. Relógio injetado nas telas e massa determinística de 10 mil/50 mil transações cobertos por testes. CI Windows/Ubuntu e builds manuais configurados; execução remota ainda pendente. [Relatório](implementation/RELATORIO_FASE_0.md).

Linha de base executada em Windows com Flutter 3.47.7: análise sem problemas e 108 testes aprovados, incluindo backup criptografado, restauração, rollback e goldens. As datas da tabela histórica abaixo preservam sua validação original; não indicam nova execução de integração ou instalação física.

Status por fase e limitações: [progresso V3](implementation/PROGRESSO_V3.md). Faturas/pagamentos e backup v2 foram implementados localmente; PR/CI e validação Android em dispositivo permanecem como gates.

| Funcionalidade | Implementada | Testada | Integração | Regressão | Última validação |
|---|---:|---:|---:|---:|---|
| Previsão mensal e agenda de pendências | Sim | Sim | Sim | Sim | 2026-09-17 |
| Confirmar pendência e desfazer | Sim | Sim | Widget | Sim | 2026-09-17 |
| Editar valor/descrição de lançamento individual | Sim | Sim | Widget | Sim | 2026-09-17 |
| Filtro mensal/conta e totais contextuais | Sim | Sim | Sim | Sim | 2026-09-17 |
| Tema e ocultação de valores persistentes | Sim | Sim | Sim | Sim | 2026-09-17 |
| Evolução interativa e alertas de orçamento | Sim | Renderização | Sim | Parcial | 2026-09-17 |
| Criar conta | Sim | Sim | Sim | Sim | 2026-09-10 |
| Receita e despesa | Sim | Sim | Sim | Sim | 2026-09-10 |
| Transferência | Sim | Sim | Sim | Sim | 2026-09-10 |
| Persistência SQLite | Sim | Sim | Sim | Sim | 2026-09-10 |
| Tarefas | Sim | Sim | Sim | Sim | 2026-09-10 |
| Exclusão de tarefa com confirmação | Sim | Sim | Sim | Sim | 2026-09-15 |
| Lista de desejos/compras local | Sim | Sim | Sim | Sim | 2026-09-15 |
| Cadastrar cartão | Sim | Sim | Sim | Sim | 2026-09-10 |
| Compra no cartão | Sim | Sim | Sim | Sim | 2026-09-10 |
| Ciclo, fatura atual e limite | Sim | Sim | Sim | Sim | 2026-09-10 |
| Instituição visual da conta, com ativos locais | Sim | Sim | Sim | Sim | 2026-09-14 |
| Investimentos manuais, taxa informada e valor atual editável | Sim | Sim | Sim | Sim | 2026-09-15 |
| Alocação por classe e renda fixa por tipo/emissor/vencimento | Sim | Sim | Sim | Sim | 2026-09-14 |
| Relatórios por mês e exportação CSV local | Sim | Sim | Sim | Sim | 2026-09-14 |
| Seletor mensal, comparação anterior e modo previsto | Sim | Sim | Sim | Sim | 2026-09-14 |
| Orçamentos mensais por categoria | Sim | Sim | Sim | Sim | 2026-09-11 |
| Assinaturas recorrentes | Sim | Sim | Sim | Sim | 2026-09-11 |
| Categorias e subcategorias personalizadas | Sim | Sim | Sim | Sim | 2026-09-14 |
| Categorias vinculadas por ID, renomeação e arquivo (schema 17) | Sim, local | Sim, 161 testes na suíte | Interface Windows; Android pendente | Sim, v1/v16→v17 | 2026-10-30 |
| Categorias próprias de metas com FK | Sim, local | Sim | Não | Sim | 2026-10-30 |
| Lançamento único, recorrente e parcelado | Sim | Sim | Sim | Sim | 2026-09-14 |
| Estado pago/pendente | Sim | Sim | Sim | Sim | 2026-09-14 |
| Planejamento de salário | Sim | Sim | Sim | Sim | 2026-09-11 |
| Filtros e busca de movimentações | Sim | Sim | Sim | Sim | 2026-09-11 |
| Exclusão protegida de contas e lançamentos | Sim | Sim | Sim | Sim | 2026-09-11 |
| Distribuição salarial persistida | Sim | Sim | Sim | Sim | 2026-09-11 |
| Data escolhida e subcategoria persistida no lançamento | Sim | Sim | Sim | Sim | 2026-09-11 |
| Parcelas distribuídas entre faturas | Sim | Sim | Sim | Sim | 2026-09-11 |
| Mapa anual de gastos | Sim | Sim | Sim | Sim | 2026-09-11 |
| Metas financeiras e aportes | Sim | Sim | Sim | Sim | 2026-09-11 |
| Migração schema 1 → 11 | Sim | Sim | Sim | Sim | 2026-09-16 |
| Salário apenas por categoria e recorrência sob demanda | Sim | Sim | Parcial | Sim | 2026-09-16 |
| Ajuste de saldo atual sem apagar movimentações | Sim | Sim | Sim | Sim | 2026-09-16 |
| Dia de crédito de rendimento informado | Sim | Sim | Sim | Sim | 2026-09-16 |
| Calendário de vencimentos na visão geral | Sim | Sim | Sim | Sim | 2026-09-16 |
| Barra móvel configurável e ação central | Sim | Sim | Sim | Sim | 2026-09-16 |
| Assinaturas editáveis e pausáveis | Sim | Sim | Sim | Sim | 2026-09-16 |
| Categorias de metas e orçamento criadas pelo usuário | Sim | Sim | Não | Sim | 2026-09-16 |
| Pizza interativa de despesas por categoria | Sim | Sim | Sim | Sim | 2026-09-16 |
| Pagamento, faturas, projeção e relatórios por competência | Sim, local | Sim, 184 testes | Windows, 2 fluxos | Sim | 2026-10-30; CI do PR pendente |
| Auditoria schema 19, exclusão lógica, backup de tombstones e “Desfazer” | Sim, local | Sim, 194 testes; 73,54% cobertura | Windows, 2 fluxos; CI do PR pendente | Sim, migração v1/v18 e widget | 2026-10-30 |
| Backup atual criptografado e snapshot | Sim, formato v1 | Sim | Não nesta execução | Sim, autenticação/restauração/rollback | 2026-10-29 |
| Backup v2 com banco consistente, imagens e prévia | Sim, em desenvolvimento | Sim | Teste coordenador Windows | Sim, unidade e integração de serviços | 2026-10-30 |
| Backup automático e rotação em pasta escolhida | Sim, em desenvolvimento | Sim | Windows; Android sem dispositivo de teste | Parcial, pasta Windows e agendamento | 2026-10-30 |
| Build Windows | Sim | — | Sim | Sim | 2026-09-14 |
