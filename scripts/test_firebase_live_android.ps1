param([string]$DeviceId = 'emulator-5556')

$ErrorActionPreference = 'Stop'
if ($DeviceId -notmatch '^[a-zA-Z0-9._:-]+$') {
    throw 'Invalid Android device ID.'
}

. (Join-Path $PSScriptRoot 'use_local_toolchain.ps1')
$projectRoot = Split-Path -Parent $PSScriptRoot
$configPath = Join-Path $projectRoot 'config\firebase.local.json'
if (-not (Test-Path -LiteralPath $configPath)) {
    throw 'Missing ignored config/firebase.local.json. Run configure_firebase.ps1 first.'
}

$config = Get-Content -LiteralPath $configPath -Raw | ConvertFrom-Json
if ($config.FIREBASE_MODE -ne 'live') {
    throw "Live acceptance requires FIREBASE_MODE=live, got '$($config.FIREBASE_MODE)'."
}
if ($config.FIREBASE_PROJECT_ID -ne 'muenee-pj') {
    throw "Live acceptance refuses project '$($config.FIREBASE_PROJECT_ID)'."
}

$env:_JAVA_OPTIONS = '-Xmx768m -XX:MaxMetaspaceSize=384m -XX:ReservedCodeCacheSize=128m -XX:ActiveProcessorCount=2'
$env:GRADLE_OPTS = '-Dorg.gradle.project.kotlin.compiler.execution.strategy=in-process -Dorg.gradle.daemon=false'
$env:DEBUG = $null

Push-Location $projectRoot
try {
    & flutter test integration_test/firebase_connection_test.dart --no-pub `
        --timeout 5m -d $DeviceId `
        --dart-define-from-file=config/firebase.local.json
    if ($LASTEXITCODE -ne 0) {
        throw "Live Android Firebase integration failed with exit code $LASTEXITCODE."
    }
}
finally {
    Pop-Location
}
