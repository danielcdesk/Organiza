# Checklist de publicação

## Antes de gerar artefatos

- [ ] Atualizar `version` e `versionCode` no `pubspec.yaml`.
- [ ] Rodar `flutter pub get`, `flutter analyze` e `flutter test`.
- [ ] Confirmar que a migração SQLite e o `technical_dossier.md` usam o mesmo schema.
- [ ] Atualizar sobre uma base schema 19 e restaurar um backup do schema 21,
      conferindo classificação, fonte de receita, dívida, parcela e conta
      recorrente; verificar que a projeção não duplica pagamentos confirmados.
- [ ] Revisar a política de privacidade com a identidade jurídica e o canal de suporte do publicador.
- [ ] Confirmar que o manifesto Android mantém `android:allowBackup="false"` e que o fluxo de backup manual está documentado.
- [ ] Revisar permissões do APK de release: `POST_NOTIFICATIONS` existe apenas para lembretes opcionais, `USE_BIOMETRIC`/credencial do sistema é usado pelo bloqueio, `VIBRATE` é usado no alerta, e não há `INTERNET` nem `SCHEDULE_EXACT_ALARM` (as variantes debug/profile do Flutter podem incluir `INTERNET` para ferramentas de desenvolvimento).
- [ ] Testar ativar/recusar notificações, texto com “ocultar valores”, bloqueio ao abrir/retornar e prévia protegida em Android recentes; confirmar que recusar notificações não impede o uso.
- [ ] Testar Windows com bloqueio ao minimizar/ocultar ativado e desativado. Confirmar que o app não grava PIN/biometria e que a declaração de segurança não promete cifra do SQLite (SQLCipher segue em avaliação).

## Android / Google Play

- [ ] Configurar a chave de release fora do repositório com `ORGANIZA_KEYSTORE_PATH` e `ORGANIZA_SIGNING_PASSWORD`.
- [ ] Executar `tooling/build_android_release.ps1`; o AAB fica em `build/app/outputs/bundle/release`.
- [ ] Verificar o `targetSdk` final do AAB; para o ciclo de 2026, o Google exige API 36 para novos apps e atualizações.
- [ ] Preencher a declaração de recursos financeiros no Play Console. O Organiza contém carteira de investimentos, saldos e planejamento financeiro, mesmo sem movimentar dinheiro.
- [ ] Preencher Data safety e o formulário de conteúdo, incluindo o uso local de fotos e arquivos exportados.
- [ ] Fazer o teste fechado exigido pela conta antes de solicitar produção; registrar os participantes e os dias do teste.
- [ ] Instalar o AAB em pelo menos um aparelho físico e um emulador suportado; testar criação de perfil, backup, restauração e atualização sobre uma base anterior.

## Windows

- [ ] Executar `flutter build windows --release`.
- [ ] Executar `tooling/package_windows_build.ps1 -BuildId <id>`.
- [ ] Testar `Organiza.exe` a partir da pasta `builds/local/<id>` em uma conta Windows limpa.
- [ ] Rodar o teste de integração Windows a partir de um caminho curto: neste
      checkout, o MSBuild excede o limite de 260 caracteres antes de compilar.
- [ ] Decidir entre MSIX e instalador tradicional e obter certificado de assinatura de código antes da distribuição pública.

## Registro

Cada versão deve ter uma pasta em `builds/local/<build-id>` para teste e outra em `builds/github/<build-id>` para os artefatos destinados ao GitHub. O identificador deve aparecer no changelog e nas notas de release.
