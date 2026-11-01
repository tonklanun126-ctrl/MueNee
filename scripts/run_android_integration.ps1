# Called by test_firebase_android.ps1 inside the local emulator lifecycle.
param(
    [string]$DeviceId,
    [switch]$Auth,
    [switch]$MealSelection,
    [switch]$DailyTracking,
    [switch]$FoodScan,
    [switch]$Phase15,
    [switch]$UseApplicationBinary
)

$ErrorActionPreference = 'Stop'
if ($env:GCLOUD_PROJECT -ne 'demo-muenee-pj' -or $env:FIRESTORE_EMULATOR_HOST -ne '127.0.0.1:8080') {
    throw 'Run through scripts/test_firebase_android.ps1 with the isolated demo emulator.'
}
. (Join-Path $PSScriptRoot 'use_local_toolchain.ps1')
$env:_JAVA_OPTIONS = '-Xmx768m -XX:MaxMetaspaceSize=384m -XX:ReservedCodeCacheSize=128m -XX:ActiveProcessorCount=2'
$env:GRADLE_OPTS = '-Dorg.gradle.project.kotlin.compiler.execution.strategy=in-process -Dorg.gradle.daemon=false'
$env:DEBUG = $null
$testTarget = 'integration_test/firebase_connection_test.dart'
if ($Auth) {
    if ($env:FIREBASE_AUTH_EMULATOR_HOST -ne '127.0.0.1:9099') { throw 'Auth emulator is required.' }
    $testTarget = 'integration_test/auth_flow_test.dart'
}
if ($MealSelection) {
    if ($env:FIREBASE_AUTH_EMULATOR_HOST -ne '127.0.0.1:9099') { throw 'Auth emulator is required.' }
    $testTarget = 'integration_test/phase_12_meal_selection_test.dart'
}
if ($DailyTracking) {
    if ($env:FIREBASE_AUTH_EMULATOR_HOST -ne '127.0.0.1:9099') { throw 'Auth emulator is required.' }
    $testTarget = 'integration_test/phase_13_daily_tracking_test.dart'
}
if ($FoodScan) {
    if ($env:FIREBASE_AUTH_EMULATOR_HOST -ne '127.0.0.1:9099') { throw 'Auth emulator is required.' }
    $testTarget = 'integration_test/phase_14_food_scan_test.dart'
}
if ($Phase15) {
    $testTarget = 'integration_test/phase_15_privacy_settings_test.dart'
}
if ($Auth) {
    & flutter drive --driver=test_driver/auth_driver.dart --target=$testTarget --no-pub -d $DeviceId --dart-define=FIREBASE_MODE=emulator
    if ($LASTEXITCODE -ne 0) { throw "Flutter Auth lifecycle test failed with exit code $LASTEXITCODE." }
    & flutter drive --driver=test_driver/auth_driver.dart --target=integration_test/auth_persistence_setup_test.dart --keep-app-running --no-pub -d $DeviceId --dart-define=FIREBASE_MODE=emulator
    if ($LASTEXITCODE -ne 0) { throw "Flutter Auth persistence setup failed with exit code $LASTEXITCODE." }
    & adb -s $DeviceId shell am force-stop com.muenee.app
    if ($LASTEXITCODE -ne 0) { throw "Could not stop the setup app process with exit code $LASTEXITCODE." }
    & flutter drive --driver=test_driver/auth_driver.dart --target=integration_test/auth_persistence_verify_test.dart --no-pub -d $DeviceId --dart-define=FIREBASE_MODE=emulator
} elseif ($DailyTracking) {
    & flutter drive --driver=test_driver/phase_13_driver.dart --target=$testTarget --no-pub -d $DeviceId --dart-define=FIREBASE_MODE=emulator
} elseif ($FoodScan) {
    if ($UseApplicationBinary) {
        & flutter drive --driver=test_driver/phase_14_driver.dart --target=$testTarget --no-pub -d $DeviceId --use-application-binary=build/app/outputs/flutter-apk/app-debug.apk
    } else {
        & flutter drive --driver=test_driver/phase_14_driver.dart --target=$testTarget --no-pub -d $DeviceId --dart-define=FIREBASE_MODE=emulator
    }
} elseif ($Phase15) {
    & flutter drive --driver=test_driver/phase_15_driver.dart --target=$testTarget --no-pub -d $DeviceId --dart-define=FIREBASE_MODE=emulator
} else {
    & flutter test $testTarget --no-pub --timeout 5m -d $DeviceId --dart-define=FIREBASE_MODE=emulator
}
if ($LASTEXITCODE -ne 0) { throw "Flutter integration test failed with exit code $LASTEXITCODE." }
