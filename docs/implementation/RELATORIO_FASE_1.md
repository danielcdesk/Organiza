# Relatório da Fase 1 — Backup e restauração

Data: 2026-10-30. Estado: implementação local validada no Windows e compilada no Android; execução real em Android ainda não validada por falta de dispositivo/emulador.

## 1. Resumo

Backup `.organizabak` v2 com ZIP cifrado por AES-256-GCM/Argon2id, manifesto, cópia SQLite consistente e imagens portáteis. Restauração prepara, migra, valida e mostra prévia antes de substituir o banco, preservando uma cópia anterior. JSON v1 continua legível. Agendamento com pasta escolhida, rotação e senha protegida pelo sistema. A UI de Configurações permite exportar, restaurar e configurar o agendamento.

## 2. Arquivos

Núcleo: `lib/database/app_database.dart`, `lib/data/local_repository.dart`, `lib/application/organiza_store.dart`, `lib/services/backup_service.dart`, `lib/services/backup_archive_service.dart`, `lib/services/backup_coordinator.dart`, `lib/services/backup_folder_service.dart`, `lib/services/secret_vault.dart`, `lib/services/app_storage_paths.dart`, `lib/services/local_image_service.dart`, `lib/domain/backup_schedule.dart`. Interface: `lib/presentation/organiza_app.dart`, `lib/presentation/basic_pages.dart`, diálogos, lista de desejos e `lib/main.dart`. Android: `MainActivity.kt`. Dependências: `archive`, `ffi`.

## 3. Migrações

O schema de produção permanece em **16**. Referências absolutas a imagens existentes são copiadas e reescritas em uma transação no primeiro início. Banco antigo vindo de backup é migrado numa cópia antes da troca. Migração de arquivo v1 e v15 para o schema 16, idempotência e saldo preservado foram testados. O teste de schema 16 para uma versão futura dependerá da primeira migração da Fase 2.

## 4. Comandos e resultados reais

- `flutter pub get`: passou após remover `flutter_secure_storage` incompatível com o compilador Windows disponível (faltava ATL).
- `flutter analyze --no-pub`: sem problemas.
- `flutter test --no-pub --coverage`: **151 testes aprovados**, cobertura **6.950/10.258 linhas, 67,75%**.
- `flutter test integration_test -d windows --no-pub`: **2 fluxos aprovados** e compilação Windows Debug bem-sucedida.
- `flutter build apk --debug --no-pub`: APK compilado com `MainActivity.kt` atualizado.
- Teste do coordenador: exportar, alterar dados, restaurar recupera saldo de **87.655 centavos**, preferências e imagem; senha errada e conflito de imagem preservam dados atuais; JSON v1 é lido.
- `git diff --check`: sem erros de whitespace.
- Revisão independente encontrou dois casos corrigidos: escolha de pasta agora só é confirmada após todos os diálogos; pasta `Organiza/images` e suas subpastas são recusadas para backup agendado. Teste da restrição Windows aprovado.

## 5. Não validado

Não havia dispositivo Android nem emulador conectado. A seleção persistente de pasta, Android Keystore e restauração na UI Android passaram pela compilação, mas não por execução real. O backup ao ir para segundo plano no Android depende de o sistema permitir que o processo termine; a UI explica esse limite.

## 6. Riscos e pendências

Backups com imagens que já faltavam na origem não recriam esses arquivos. JSON v1 não continha imagens. O container limita banco a 64 MiB, imagem individual a 10 MiB e extração total a 128 MiB. O agendamento roda ao iniciar e enquanto o aplicativo está ativo; não usa serviço de background. A versão de distribuição ainda não foi assinada nem publicada. O banco local continua sem cifra por padrão até a Fase 4.

## 7. Decisões

Senha de backup agendado guardada no cofre do sistema, autorizada pelo dono do produto. Windows usa DPAPI; Android usa Android Keystore. A pasta Android é escolhida via Storage Access Framework, sem permissão ampla de arquivos. Dívidas seguem adiadas; cartão e criptografia do banco seguem as decisões documentadas.

## 8. Próxima fase e perguntas

Iniciar Fase 2 após o registro desta fase e CI verde do PR da Fase 1. O teste de execução Android em dispositivo físico fica como verificação adicional antes de uma distribuição Android. Nenhuma decisão nova de produto é necessária para iniciar categorias com FK (schema 17).
