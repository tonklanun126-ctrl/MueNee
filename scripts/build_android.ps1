param([switch]$Emulator, [switch]$X64)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'use_local_toolchain.ps1')
$projectDirectory = Split-Path -Parent $PSScriptRoot
$configFile = Join-Path $projectDirectory 'config\firebase.local.json'
if (-not $Emulator -and -not (Test-Path -LiteralPath $configFile)) {
    throw 'Run scripts/configure_firebase.ps1 with the downloaded google-services.json first, or pass -Emulator.'
}
$androidConfigFile = Join-Path $projectDirectory 'android\app\google-services.json'
if (-not $Emulator -and -not (Test-Path -LiteralPath $androidConfigFile)) {
    throw 'Place the validated google-services.json at android/app/google-services.json before a live-config build.'
}
$env:_JAVA_OPTIONS = '-Xmx768m -XX:MaxMetaspaceSize=384m -XX:ReservedCodeCacheSize=128m -XX:ActiveProcessorCount=2'
$env:GRADLE_OPTS = '-Dorg.gradle.project.kotlin.compiler.execution.strategy=in-process -Dorg.gradle.daemon=false'
# The Gradle Windows wrapper echoes build defines when DEBUG is inherited.
$env:DEBUG = $null
$buildArguments = @('build','apk','--debug','--no-pub')
if ($Emulator) { $buildArguments += '--dart-define=FIREBASE_MODE=emulator' }
else { $buildArguments += "--dart-define-from-file=$configFile" }
if ($X64) { $buildArguments += '--target-platform=android-x64' }
$mapsConfigFile = Join-Path $projectDirectory 'config\maps.local.json'
if (Test-Path -LiteralPath $mapsConfigFile) {
    $buildArguments += "--dart-define-from-file=$mapsConfigFile"
}
Push-Location $projectDirectory
try {
    & flutter @buildArguments
    if ($LASTEXITCODE -ne 0) { throw "Android build failed with exit code $LASTEXITCODE." }
}
finally { Pop-Location }
