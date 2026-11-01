param([string]$DeviceId = 'emulator-5554')

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'use_local_toolchain.ps1')
$env:_JAVA_OPTIONS = '-Xmx768m -XX:MaxMetaspaceSize=384m -XX:ReservedCodeCacheSize=128m -XX:ActiveProcessorCount=2'
$env:GRADLE_OPTS = '-Dorg.gradle.project.kotlin.compiler.execution.strategy=in-process -Dorg.gradle.daemon=false'
$env:DEBUG = $null

Push-Location (Split-Path -Parent $PSScriptRoot)
try {
    & flutter drive --driver=test_driver/coral_companion_driver.dart `
        --target=integration_test/coral_companion_visual_test.dart `
        --no-pub -d $DeviceId --dart-define=FIREBASE_MODE=emulator
    if ($LASTEXITCODE -ne 0) { throw "Coral Companion Android visual test failed with exit code $LASTEXITCODE." }
}
finally { Pop-Location }
