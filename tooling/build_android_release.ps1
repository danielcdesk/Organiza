param(
    [switch]$SplitOnly,
    [switch]$AllowTestSigning
)

$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$flutterCommand = Get-Command flutter -ErrorAction SilentlyContinue
if (-not $flutterCommand) { throw 'Flutter não encontrado no PATH.' }
$flutter = $flutterCommand.Source

if ($AllowTestSigning) {
    $env:ORGANIZA_PREVIEW_BUILD = '1'
    & $flutter build apk --release --target-platform android-arm,android-arm64,android-x64
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
    $source = Join-Path $projectRoot 'build\app\outputs\flutter-apk\app-release.apk'
    $destination = Join-Path $projectRoot 'build\app\outputs\flutter-apk\Organiza-Android-TEST-SIGNED.apk'
    Copy-Item -LiteralPath $source -Destination $destination -Force
    Write-Host "APK de teste separado: $destination" -ForegroundColor Yellow
    exit 0
}

if (-not $env:ORGANIZA_KEYSTORE_PATH -or -not $env:ORGANIZA_SIGNING_PASSWORD) {
    throw 'Build de distribuição exige ORGANIZA_KEYSTORE_PATH e ORGANIZA_SIGNING_PASSWORD. Para teste separado, use -AllowTestSigning.'
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
