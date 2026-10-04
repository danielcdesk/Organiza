param(
    [switch]$SplitOnly
)

$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$flutterCommand = Get-Command flutter -ErrorAction SilentlyContinue
if (-not $flutterCommand) { throw 'Flutter não encontrado no PATH.' }
$flutter = $flutterCommand.Source

if (-not $env:ORGANIZA_KEYSTORE_PATH -or -not $env:ORGANIZA_SIGNING_PASSWORD) {
    $keystore = Join-Path $projectRoot 'build\signing\organiza-test.keystore'
    New-Item -ItemType Directory -Force -Path (Split-Path $keystore) | Out-Null
    if (-not (Test-Path -LiteralPath $keystore)) {
        $keytool = if ($env:JAVA_HOME) {
            Join-Path $env:JAVA_HOME 'bin\keytool.exe'
        } else {
            (Get-Command keytool -ErrorAction SilentlyContinue).Source
        }
        if (-not $keytool -or -not (Test-Path -LiteralPath $keytool)) {
            throw 'keytool não encontrado para criar a assinatura local.'
        }
        & $keytool -genkeypair -v -keystore $keystore -storepass 'organiza-test' -keypass 'organiza-test' `
            -alias organiza -keyalg RSA -keysize 2048 -validity 10000 `
            -dname 'CN=Organiza, OU=Local, O=Organiza, L=Local, ST=SP, C=BR'
        if ($LASTEXITCODE -ne 0) { throw 'Não foi possível criar a assinatura local.' }
    }
    $env:ORGANIZA_KEYSTORE_PATH = $keystore
    $env:ORGANIZA_SIGNING_PASSWORD = 'organiza-test'
}

& $flutter build apk --release --split-per-abi
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
if (-not $SplitOnly) {
    & $flutter build apk --release --target-platform android-arm,android-arm64,android-x64
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
}
& $flutter build appbundle --release
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
Write-Host 'APKs e AAB Android assinados gerados em build\app\outputs.' -ForegroundColor Green
