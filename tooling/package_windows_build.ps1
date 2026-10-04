param(
    [Parameter(Mandatory = $true)]
    [string]$BuildId
)

$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$releaseDirectory = Join-Path $projectRoot 'build\windows\x64\runner\Release'

if (-not (Test-Path -LiteralPath (Join-Path $releaseDirectory 'organiza.exe'))) {
    throw "Build Windows não encontrada em $releaseDirectory. Execute flutter build windows --release primeiro."
}

$destinations = @(
    (Join-Path $projectRoot "builds\local\$BuildId"),
    (Join-Path $projectRoot "builds\github\$BuildId\windows")
)

foreach ($destination in $destinations) {
    New-Item -ItemType Directory -Force -Path $destination | Out-Null

    Get-ChildItem -LiteralPath $releaseDirectory -Force |
        Where-Object { $_.Name -ne 'organiza.exe' } |
        ForEach-Object {
            Copy-Item -LiteralPath $_.FullName `
                -Destination (Join-Path $destination $_.Name) `
                -Recurse -Force
        }

    Copy-Item -LiteralPath (Join-Path $releaseDirectory 'organiza.exe') `
        -Destination (Join-Path $destination 'Organiza.exe') -Force
}

$apkOutputDirectory = Join-Path $projectRoot 'build\app\outputs\flutter-apk'
$apk = Join-Path $apkOutputDirectory 'app-release.apk'
$aab = Join-Path $projectRoot 'build\app\outputs\bundle\release\app-release.aab'
if (Test-Path -LiteralPath $apk) {
    $androidDestinations = @(
        (Join-Path $projectRoot "builds\local\$BuildId\android"),
        (Join-Path $projectRoot "builds\github\$BuildId\android")
    )
    foreach ($destination in $androidDestinations) {
        New-Item -ItemType Directory -Force -Path $destination | Out-Null
        Copy-Item -LiteralPath $apk `
            -Destination (Join-Path $destination 'Organiza-Android.apk') -Force

        $splitApks = @(
            @{ Source = 'app-armeabi-v7a-release.apk'; Name = 'Organiza-Android-armeabi-v7a.apk' },
            @{ Source = 'app-arm64-v8a-release.apk'; Name = 'Organiza-Android-arm64-v8a.apk' },
            @{ Source = 'app-x86_64-release.apk'; Name = 'Organiza-Android-x86_64.apk' }
        )
        foreach ($split in $splitApks) {
            $splitSource = Join-Path $apkOutputDirectory $split.Source
            if (Test-Path -LiteralPath $splitSource) {
                Copy-Item -LiteralPath $splitSource `
                    -Destination (Join-Path $destination $split.Name) -Force
            }
        }
    }
}

if (Test-Path -LiteralPath $aab) {
    $aabDestinations = @(
        (Join-Path $projectRoot "builds\local\$BuildId\android"),
        (Join-Path $projectRoot "builds\github\$BuildId\android")
    )
    foreach ($destination in $aabDestinations) {
        New-Item -ItemType Directory -Force -Path $destination | Out-Null
        Copy-Item -LiteralPath $aab `
            -Destination (Join-Path $destination 'Organiza-Android.aab') -Force
    }
}

$localBuildDirectory = Join-Path $projectRoot "builds\local\$BuildId"
$installerScript = Join-Path $localBuildDirectory 'Instalar-no-emulador.ps1'
@'
$ErrorActionPreference = 'Stop'
$buildRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$androidRoot = Join-Path $buildRoot 'android'
$adbCandidates = @()
if ($env:ANDROID_HOME) { $adbCandidates += Join-Path $env:ANDROID_HOME 'platform-tools\adb.exe' }
if ($env:ANDROID_SDK_ROOT) { $adbCandidates += Join-Path $env:ANDROID_SDK_ROOT 'platform-tools\adb.exe' }
if ($env:LOCALAPPDATA) { $adbCandidates += Join-Path $env:LOCALAPPDATA 'Android\Sdk\platform-tools\adb.exe' }
$adb = $adbCandidates | Where-Object { $_ -and (Test-Path -LiteralPath $_) } | Select-Object -First 1
if (-not $adb) { throw 'ADB não encontrado. Abra o Android Studio ou defina ANDROID_HOME.' }

$devices = & $adb devices | Select-String '\sdevice$'
if (-not $devices) { throw 'Nenhum emulador conectado. Inicie o emulador e execute novamente.' }
$serial = $null
$abis = $null
foreach ($device in $devices) {
    $candidate = ($device.ToString().Trim() -split '\s+')[0]
    $candidateAbis = (& $adb -s $candidate shell getprop ro.product.cpu.abilist 2>$null).Trim()
    if ($candidateAbis -match 'x86_64') {
        $serial = $candidate
        $abis = $candidateAbis
        break
    }
    if (-not $serial -and $candidateAbis -match 'arm64-v8a|armeabi-v7a') {
        $serial = $candidate
        $abis = $candidateAbis
    }
}
if (-not $serial) { throw 'Nenhum dispositivo conectado respondeu com uma arquitetura Android suportada.' }

$apkName = if ($abis -match 'x86_64') {
    'Organiza-Android-x86_64.apk'
} elseif ($abis -match 'arm64-v8a') {
    'Organiza-Android-arm64-v8a.apk'
} elseif ($abis -match 'armeabi-v7a') {
    'Organiza-Android-armeabi-v7a.apk'
} else {
    throw "Arquitetura não suportada pelo Flutter atual (use um emulador x86_64 ou arm64): $abis"
}
$apk = Join-Path $androidRoot $apkName
if (-not (Test-Path -LiteralPath $apk)) { throw "APK correspondente não encontrado: $apkName" }
Write-Host "Dispositivo: $serial" -ForegroundColor Cyan
Write-Host "Arquiteturas: $abis" -ForegroundColor Cyan
Write-Host "Instalando: $apkName" -ForegroundColor Green
& $adb -s $serial install --no-streaming -r -d $apk
if ($LASTEXITCODE -ne 0) { throw "O ADB retornou o código $LASTEXITCODE. Reinicie o emulador e tente novamente." }
Write-Host 'Instalação concluída.' -ForegroundColor Green
Read-Host 'Pressione Enter para fechar'
'@ | Set-Content -LiteralPath $installerScript -Encoding UTF8

@'
@echo off
powershell.exe -ExecutionPolicy Bypass -File "%~dp0Instalar-no-emulador.ps1"
if errorlevel 1 pause
'@ | Set-Content -LiteralPath (Join-Path $localBuildDirectory 'Instalar-no-emulador.bat') -Encoding ASCII

@"
ORGANIZA — BUILD $BuildId

Execute Organiza.exe com dois cliques e mantenha todos os arquivos desta pasta juntos.
O APK universal fica em android\Organiza-Android.apk e o AAB de publicação em android\Organiza-Android.aab.
Os artefatos Android desta pasta usam a chave de teste local quando nenhuma chave de produção foi configurada.
Para instalar no emulador, execute Instalar-no-emulador.bat; ele escolhe a arquitetura correta.
"@ | Set-Content -LiteralPath (Join-Path $projectRoot "builds\local\$BuildId\LEIA-ME.txt") -Encoding UTF8

Write-Host "Build copiada para:" -ForegroundColor Green
$destinations | ForEach-Object { Write-Host " - $_" }
