param(
    [string]$DeviceId = 'emulator-5556',
    [switch]$Auth,
    [switch]$MealSelection,
    [switch]$DailyTracking,
    [switch]$FoodScan,
    [switch]$Phase15,
    [switch]$UseApplicationBinary
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'use_local_toolchain.ps1')
$jdk21 = Get-ChildItem -LiteralPath (Join-Path $mueneeTooling 'jdk') -Directory -Filter 'jdk-21*' | Sort-Object Name -Descending | Select-Object -First 1
if ($null -eq $jdk21) { throw 'Install Java 21 under .tooling/jdk for Firebase emulators.' }
$env:JAVA_HOME = $jdk21.FullName
$env:PATH = "$env:JAVA_HOME\bin;$env:PATH"
$env:_JAVA_OPTIONS = '-Xmx512m -XX:MaxMetaspaceSize=192m -XX:ActiveProcessorCount=2'
$env:DEBUG = $null
if ($DeviceId -notmatch '^[a-zA-Z0-9._:-]+$') { throw 'Invalid Android device ID.' }
Push-Location (Split-Path -Parent $PSScriptRoot)
try {
    $emulators = 'firestore'
    $authArgument = ''
    $scenarioCount = @($Auth, $MealSelection, $DailyTracking, $FoodScan, $Phase15).Where({ $_ }).Count
    if ($scenarioCount -gt 1) {
        throw 'Choose only one Android Firebase integration scenario.'
    }
    if ($Auth) { $emulators = 'auth,firestore'; $authArgument = ' -Auth' }
    if ($MealSelection) { $emulators = 'auth,firestore'; $authArgument = ' -MealSelection' }
    if ($DailyTracking) { $emulators = 'auth,firestore'; $authArgument = ' -DailyTracking' }
    if ($FoodScan) { $emulators = 'auth,firestore'; $authArgument = ' -FoodScan' }
    if ($Phase15) { $authArgument = ' -Phase15' }
    if ($UseApplicationBinary) { $authArgument += ' -UseApplicationBinary' }
    & node node_modules/firebase-tools/lib/bin/firebase.js emulators:exec --project demo-muenee-pj --only $emulators "powershell -NoProfile -ExecutionPolicy Bypass -File scripts/run_android_integration.ps1 -DeviceId $DeviceId$authArgument"
    if ($LASTEXITCODE -ne 0) { throw "Android Firebase integration failed with exit code $LASTEXITCODE." }
}
finally { Pop-Location }
