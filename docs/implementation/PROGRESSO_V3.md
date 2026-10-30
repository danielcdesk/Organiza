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

Schema 18, compra com categoria/data, regras de ciclo e parcelas, pagamentos parciais idempotentes com estorno, projeção de obrigações, relatórios/orçamentos e UI estão implementados localmente. Análise limpa; 175 testes passaram com 72,58% de cobertura; integração Windows passou com 2 fluxos. A compilação APK local não pôde iniciar porque o Android SDK não está instalado/configurado. Relatório em `RELATORIO_FASE_2_2.md`. Revisão, PR draft e CI são os gates restantes antes de avançar.
