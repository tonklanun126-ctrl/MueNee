$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$configPath = Join-Path $projectRoot 'config\firebase.local.json'
if (-not (Test-Path -LiteralPath $configPath)) {
    throw 'Missing ignored config/firebase.local.json. Run configure_firebase.ps1 first.'
}

$config = Get-Content -LiteralPath $configPath -Raw | ConvertFrom-Json
if ($config.FIREBASE_MODE -ne 'live' -or $config.FIREBASE_PROJECT_ID -ne 'muenee-pj') {
    throw 'Live rules probe only permits FIREBASE_MODE=live for muenee-pj.'
}
if ([string]::IsNullOrWhiteSpace($config.FIREBASE_API_KEY)) {
    throw 'Live Firebase API key is missing.'
}

Add-Type -AssemblyName System.Net.Http
$client = [System.Net.Http.HttpClient]::new()
try {
    $projectId = [Uri]::EscapeDataString($config.FIREBASE_PROJECT_ID)
    $apiKey = [Uri]::EscapeDataString($config.FIREBASE_API_KEY)
    $uri = "https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents/_phase2_probe/no-data?key=$apiKey"
    $response = $client.GetAsync($uri).GetAwaiter().GetResult()
    $body = $response.Content.ReadAsStringAsync().GetAwaiter().GetResult()
    $status = [int]$response.StatusCode

    $reason = $null
    try { $reason = ($body | ConvertFrom-Json).error.status } catch { }
    if ($status -ne 403 -or $reason -ne 'PERMISSION_DENIED') {
        throw "Expected HTTP 403 PERMISSION_DENIED, got HTTP $status $reason."
    }

    Write-Output 'LIVE_FIRESTORE_RULES=HTTP_403_PERMISSION_DENIED'
    Write-Output 'LIVE_FIRESTORE_WRITE_ATTEMPTED=False'
}
finally {
    $client.Dispose()
}
