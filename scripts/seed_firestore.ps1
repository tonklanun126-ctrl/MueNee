param(
    [Parameter(Mandatory = $true)]
    [string]$ConfirmProject,
    [string]$ProjectId = 'muenee-pj',
    [string]$ExpectedLocation = 'asia-southeast1',
    [switch]$PreflightOnly,
    [switch]$VerifyOnly
)

$ErrorActionPreference = 'Stop'
$originalApplicationData = $env:APPDATA
. (Join-Path $PSScriptRoot 'use_local_toolchain.ps1')
if ($ConfirmProject -ne $ProjectId) { throw "Refusing live seed: ConfirmProject '$ConfirmProject' does not match '$ProjectId'." }
if ($env:FIRESTORE_EMULATOR_HOST) { throw 'Refusing live seed while FIRESTORE_EMULATOR_HOST is set.' }
if ($PreflightOnly -and $VerifyOnly) { throw 'Choose either PreflightOnly or VerifyOnly.' }
if (-not $env:GOOGLE_APPLICATION_CREDENTIALS -and $originalApplicationData) {
    $defaultCredential = Join-Path $originalApplicationData 'gcloud\application_default_credentials.json'
    if (Test-Path -LiteralPath $defaultCredential) {
        $env:GOOGLE_APPLICATION_CREDENTIALS = $defaultCredential
    }
}

$jdk21 = Get-ChildItem -LiteralPath (Join-Path $mueneeTooling 'jdk') -Directory -Filter 'jdk-21*' |
    Sort-Object Name -Descending |
    Select-Object -First 1
if ($null -eq $jdk21) { throw 'Firebase CLI 15 requires Java 21 in the sibling .tooling/jdk directory.' }
$env:JAVA_HOME = $jdk21.FullName
$env:PATH = "$env:JAVA_HOME\bin;$env:PATH"
$env:DEBUG = $null

$projectRoot = Split-Path -Parent $PSScriptRoot
$firebaseCli = Join-Path $projectRoot 'node_modules\firebase-tools\lib\bin\firebase.js'
if (-not (Test-Path -LiteralPath $firebaseCli)) { throw 'Firebase CLI is missing. Run npm ci before seeding.' }

Push-Location $projectRoot
try {
    $databaseJson = & node $firebaseCli firestore:databases:get '(default)' --project $ProjectId --json
    if ($LASTEXITCODE -ne 0) { throw 'Could not inspect the live Firestore database.' }
    $database = $databaseJson | ConvertFrom-Json
    if ($database.status -ne 'success' -or $null -eq $database.result) { throw 'Firebase CLI returned an unexpected database response.' }
    if ($database.result.locationId -ne $ExpectedLocation) { throw "Refusing live seed: database location is '$($database.result.locationId)', expected '$ExpectedLocation'." }
    if ($database.result.type -ne 'FIRESTORE_NATIVE') { throw "Refusing live seed: database type is '$($database.result.type)', expected FIRESTORE_NATIVE." }
    Write-Output "Verified live target: project=$ProjectId location=$ExpectedLocation type=FIRESTORE_NATIVE."
    $operation = if ($PreflightOnly) { '--preflight' } elseif ($VerifyOnly) { '--verify' } else { '--write' }
    & node scripts/seed_firestore.mjs $operation --live --project $ProjectId --confirm-project $ConfirmProject
    if ($LASTEXITCODE -ne 0) { throw "Firestore seed failed with exit code $LASTEXITCODE." }
}
finally { Pop-Location }
