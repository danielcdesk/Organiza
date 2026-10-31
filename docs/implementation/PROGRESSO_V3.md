# Execução V3 — 29/10/2026

Contrato: `docs/product/ORGANIZA_MEGA_PROMPT_V3.md` e auditoria de 29/10/2026.
Fonte original preservada no commit `9b86d93`, branch local `codex/organiza-v3`.
O ZIP foi extraído para uma cópia independente; não se modifica a instalação nem a base financeira do usuário.

## Linha de base executada

- Flutter 3.47.7, Dart 3.13.5, Windows.
- `flutter pub get`: aprovado, mantendo versões do lockfile.
- `flutter analyze`: sem problemas.
- `flutter test --reporter expanded`: **108 testes aprovados**.
- Schema real: 16. Versão: 0.9.0+13.
- Logs locais: `../baseline-pub-get.log`, `../baseline-analyze.log`, `../baseline-test.log`.

## Decisões do usuário nesta conversa

1. Relatórios por categoria: data da compra no cartão; pagamento reduz a conta sem repetir a despesa.
2. Dívidas/financiamentos ficam para depois.
3. Criptografia do banco ligada por padrão; PIN; biometria opcional.

## Ordem e aceite

- [x] Fase 0: CI, Dependabot, lints, relógio injetado em toda a UI, gerador de massa e documentação com verificações reais.
- [x] Fase 1: backup v2 com imagens, restauração validada entre versões e prévia, cópia de segurança, agendamento/rotação e UI. Execução Android em dispositivo ainda não validada.
- [ ] Fase 2: migrações temáticas para categorias, faturas, auditoria/exclusão lógica, contas, tags/anexos, investimentos e importação. Dívidas excluídas por decisão humana.
- [ ] Fase 3: medições, consultas SQL/paginação/FTS, cache e separação de responsabilidades. Manter sqlite3 e ChangeNotifier; Drift é opcional e depende de aprovação específica.
- [ ] Fase 4: banco cifrado por padrão, chave no armazenamento seguro, migração preservando dados, PIN e biometria opcional.
- [ ] Fase 5: importação genérica com prévia e deduplicação, regras, conciliação, UI de faturas, avisos locais, atalhos/modelos, relatórios/PDF e acessibilidade.
- [ ] Fase 6: distribuição local verificável, assinatura documentada e atualização manual.
- [ ] Fase 7: proposta de sincronização apenas; nenhuma rede no produto.

Os itens da auditoria (máscaras, emissor/contraste do cartão, logos reais, metas completas, mês atual, histórico de planejamento, próximos passos e ações rápidas) continuam obrigatórios; serão associados às fases de dados e uso diário sem antecipar migrações nem pular a validação.

## Divergências verificadas

- O estado conhecido como bom já menciona 0.9.0; não está limitado a 0.6.0 como afirma D16.
- README distingue fonte 0.9.0 de binários 0.7.1; não publicar links fictícios.
- Notas 0.9.0 citam schema 15; banco real e estado conhecido usam 16.
- Contagens antigas de 95/100 não são a linha de base atual: a execução encontrou 108 testes.
- O plano chama Drift de 3.6 numa decisão, mas a tarefa correspondente é 3.10. FTS é 3.6.
- A arquitetura recomenda Drift na próxima alteração; o contrato V3 torna a troca opcional. Manter o backend até aprovação e testes de equivalência.

## Estado corrente

Fase 0 em execução. Nenhuma fase posterior concluída. Nenhuma publicação externa autorizada ou executada.

## Atualização de execução
Fase 0 concluída: CI GitHub Actions 40964840031 verde em Windows e Ubuntu; PR https://github.com/danielcdesk/Organiza/pull/2. Pacote da Fase 0 em outputs. Usuário aprovou guardar senha de backup no cofre do sistema. Fase 1 em desenvolvimento local, ainda não publicada: APIs de banco/arquivo, transporte ZIP cifrado, imagens relativas, planner e cofre. Pendentes: coordenador de restauração atômica, prévia/UI, agendamento/rotação e SAF Android. Não promover esta árvore local como release nem marcar Fase 1 pronta. Main inicializa AppStoragePaths. Novas dependências archive4.5.2, flutter_secure_storage10.3.4 (11 incompatível com win32 do file_picker8), ffi. Reexecutar análise/suíte antes de comitar Fase 1.

## Atualização de 2026-10-30

O coordenador de backup, prévia/confirmacão, cópia de segurança, imagens relativas, agendamento, rotação e pasta Android SAF estão integrados localmente. A dependência `flutter_secure_storage` foi retirada após falha de compilação Windows por falta de ATL; o cofre agora usa DPAPI e Android Keystore. Windows: integração 2 fluxos passou e o teste do cofre passou. Android: primeiro build Debug passou antes da troca do cofre; segundo build em execução. Testes de serviços incluem senha errada, backup v1, conflito de imagem preservando banco e ida e volta com preferências. A suíte completa passou com 147 testes antes dos dois últimos testes de cofre/pasta. Ainda não declarar a Fase 1 concluída antes de análise e suíte finais, build Android atualizado e revisão da implementação. Nenhum commit da Fase 1 foi enviado.

Validação final local da Fase 1: `flutter analyze` limpo; 151 testes aprovados, cobertura 67,75%; integração Windows 2 fluxos; APK Android Debug compilado após a troca do cofre. Android em dispositivo ainda não executado. Detalhes em `RELATORIO_FASE_1.md`.

## Fase 2.1 — categorias com FK

Schema 17 implementado em commits temáticos: migração com preenchimento dos IDs, leitura/gravação por ID e interface de renomeação/arquivamento. Metas mantêm `goal_categories` como tabela separada, decisão documentada em `docs/DECISIONS.md`. Análise limpa, 161 testes aprovados com 69,13% de cobertura, incluindo migração v1/v16→v17 com saldo preservado. Dois fluxos de integração Windows passaram e três problemas importantes encontrados na revisão foram corrigidos. CI do PR é o gate restante. Relatório: `RELATORIO_FASE_2_1.md`. A Fase 2 completa continua pendente.

O PR #4 da Fase 2.1 passou no CI Windows/Ubuntu (`Qualidade Flutter`, run 41079612624). A Fase 2.2 segue em branch isolada com schema 18; a Fase 2 completa continua pendente.

## Fase 2.2 — faturas e pagamentos de cartão

Schema 18, compra por categoria/data, pagamentos idempotentes com estorno, projeção de obrigações no dashboard, tratamento transparente de marcações antigas, limites/resumos de cartão e relatórios/orçamentos estão implementados localmente. Revisão independente encontrou quatro pontos importantes, corrigidos com testes; uma lacuna menor de injeção de falha na transação foi documentada. Análise limpa, 184 testes aprovados com 73,00% de cobertura; integração Windows 2/2 passou. O build Android release sem assinatura e os jobs de qualidade Windows/Ubuntu passaram no CI run 41144349736 (`8288b91`). PR draft #5 está aberto; Fase 2.2 validada. A Fase 2 completa continua pendente das demais entregas de dados. Relatório em `RELATORIO_FASE_2_2.md`.

## Fase 2.3 — auditoria e exclusão lógica

Schema 19, filtros de tombstones nas dez entidades, snapshot/restore que preserva as linhas excluídas e snackbars “Desfazer” foram implementados. Revisão independente sem achados críticos/importantes; recomendação de usar relógio injetado também no estorno do cartão foi resolvida. Validação local: análise limpa, 194 testes aprovados, cobertura 73,54%, integração Windows 2/2. PR draft #6, run CI 41148582388, passou em Windows, Ubuntu e APK Android. Relatório: `RELATORIO_FASE_2_3.md`. A Fase 2 completa continua pendente.

## Fase 2.4 — tipo e ciclo de vida das contas (CI verde)

Schema 20 adiciona tipo de conta, moeda BRL reservada, arquivamento reversível e opção de inclusão patrimonial. Migração mantém saldos e vínculos; contas arquivadas ficam fora dos seletores de novos movimentos, preservando histórico. Patrimônio é agrupado por moeda, sem conversão. Análise limpa, 203 testes aprovados com 74,78% de cobertura, integração Windows 2/2 e revisão independente sem achados críticos/importantes. PR draft #7, CI run 41150382909 passou em Windows/Ubuntu/Android. Ver `RELATORIO_FASE_2_4.md`.

## Fase 2.5 — tags e anexos (validação local concluída; PR/CI pendentes)

Schema 21 adiciona tags reutilizáveis, vínculos transacionais e metadados dos anexos. UI oferece CRUD/seleção/filtro por tag e gestão de anexos; arquivos permitidos ficam na pasta privada e entram no backup v2. Revisão independente concluída com correções incorporadas. Análise limpa, suíte com 218 testes e 74,73% de cobertura; integração Windows 2/2. PR draft #8, CI run 41153807299 verde em Windows/Ubuntu/Android. Relatório: `RELATORIO_FASE_2_5.md`.
