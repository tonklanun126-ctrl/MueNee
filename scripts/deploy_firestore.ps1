param(
    [string]$ProjectId = 'muenee-pj',
    [string]$ExpectedLocation = 'asia-southeast1'
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'use_local_toolchain.ps1')

$jdk21 = Get-ChildItem -LiteralPath (Join-Path $mueneeTooling 'jdk') -Directory -Filter 'jdk-21*' |
    Sort-Object Name -Descending |
    Select-Object -First 1
if ($null -eq $jdk21) {
    throw 'Firebase CLI 15 requires Java 21. Install it in the sibling .tooling/jdk directory.'
}

$env:JAVA_HOME = $jdk21.FullName
$env:PATH = "$env:JAVA_HOME\bin;$env:PATH"
$env:DEBUG = $null

$projectRoot = Split-Path -Parent $PSScriptRoot
$firebaseCli = Join-Path $projectRoot 'node_modules\firebase-tools\lib\bin\firebase.js'
if (-not (Test-Path -LiteralPath $firebaseCli)) {
    throw 'Firebase CLI is missing. Run npm ci before deploying.'
}

Push-Location $projectRoot
try {
    $databaseJson = & node $firebaseCli firestore:databases:get '(default)' `
        --project $ProjectId --json
    if ($LASTEXITCODE -ne 0) {
        throw "The (default) Firestore database is unavailable. Create it explicitly in $ExpectedLocation before deploying rules."
    }

    $database = $databaseJson | ConvertFrom-Json
    if ($database.status -ne 'success' -or $null -eq $database.result) {
        throw 'Firebase CLI returned an unexpected database response.'
    }
    if ($database.result.locationId -ne $ExpectedLocation) {
        throw "Refusing to deploy: (default) is in '$($database.result.locationId)', expected '$ExpectedLocation'."
    }
    if ($database.result.type -ne 'FIRESTORE_NATIVE') {
        throw "Refusing to deploy: (default) uses '$($database.result.type)', expected FIRESTORE_NATIVE."
    }

    Write-Output "Verified (default): project=$ProjectId location=$ExpectedLocation type=FIRESTORE_NATIVE."
    & node $firebaseCli deploy --only 'firestore:rules,firestore:indexes' `
        --project $ProjectId --force
    if ($LASTEXITCODE -ne 0) {
        throw "Firestore deployment failed with exit code $LASTEXITCODE."
    }
}
finally {
    Pop-Location
}
