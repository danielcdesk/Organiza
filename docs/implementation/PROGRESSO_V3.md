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

- [ ] Fase 0: CI, Dependabot, lints, relógio injetado em toda a UI, gerador de massa e documentação com verificações reais.
- [ ] Fase 1: backup v2 com imagens, restauração validada entre versões e prévia, cópia de segurança, agendamento/rotação e UI.
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
