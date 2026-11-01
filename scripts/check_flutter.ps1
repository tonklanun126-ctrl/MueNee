$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'use_local_toolchain.ps1')
Push-Location (Split-Path -Parent $PSScriptRoot)
try {
    & dart format lib/core/firestore lib/features/auth lib/features/budget lib/features/location lib/features/profile/models lib/features/recommendation lib/features/restaurants lib/features/tracking test/auth test/budget test/firestore test/location test/recommendation test/restaurants test/tracking test_driver/auth_driver.dart test_driver/phase_13_driver.dart integration_test/auth_flow_test.dart integration_test/auth_persistence_setup_test.dart integration_test/auth_persistence_verify_test.dart integration_test/phase_10_restaurant_detail_test.dart integration_test/phase_12_meal_selection_test.dart integration_test/phase_13_daily_tracking_test.dart lib/app/theme/app_theme.dart lib/app/widgets lib/app/router/app_router.dart
    if ($LASTEXITCODE -ne 0) { throw 'Dart format failed.' }
    & flutter analyze --no-pub
    if ($LASTEXITCODE -ne 0) { throw 'Flutter analyze failed.' }
    & flutter test --no-pub --concurrency=1
    if ($LASTEXITCODE -ne 0) { throw 'Flutter tests failed.' }
} finally { Pop-Location }
