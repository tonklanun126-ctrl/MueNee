param(
    [Parameter(Mandatory = $true)][string]$GoogleServicesJson
)

$ErrorActionPreference = 'Stop'
$projectDirectory = Split-Path -Parent $PSScriptRoot
$outputPath = Join-Path $projectDirectory 'config\firebase.local.json'
$androidOutputPath = Join-Path $projectDirectory 'android\app\google-services.json'
if (Test-Path -LiteralPath $outputPath) {
    throw 'config/firebase.local.json already exists. Preserve/review it before generating another configuration.'
}
$source = Get-Content -LiteralPath $GoogleServicesJson -Raw -Encoding UTF8 | ConvertFrom-Json
if ($source.project_info.project_id -ne 'muenee-pj') {
    throw 'Expected the muenee-pj Firebase project.'
}
$clients = @($source.client | Where-Object { $_.client_info.android_client_info.package_name -eq 'com.muenee.app' })
if ($clients.Count -ne 1) { throw 'Expected exactly one com.muenee.app Android client.' }
$client = $clients[0]
$apiKeys = @($client.api_key | Where-Object { -not [string]::IsNullOrWhiteSpace($_.current_key) })
if ($apiKeys.Count -ne 1) { throw 'Expected exactly one Android client API key.' }
$senderId = [string]$source.project_info.project_number
$appId = [string]$client.client_info.mobilesdk_app_id
if ($senderId -notmatch '^\d+$' -or $appId -notmatch ('^1:' + [regex]::Escape($senderId) + ':android:[a-fA-F0-9]+$')) {
    throw 'Android App ID and Firebase project number do not match.'
}
$config = [ordered]@{
    FIREBASE_MODE = 'live'
    FIREBASE_PROJECT_ID = 'muenee-pj'
    FIREBASE_ANDROID_APP_ID = $appId
    FIREBASE_API_KEY = [string]$apiKeys[0].current_key
    FIREBASE_MESSAGING_SENDER_ID = $senderId
    FIREBASE_STORAGE_BUCKET = [string]$source.project_info.storage_bucket
}
# Generated, ignored build input. Never print API keys or include server credentials.
[IO.File]::WriteAllText($outputPath, ($config | ConvertTo-Json) + [Environment]::NewLine, [Text.UTF8Encoding]::new($false))
Copy-Item -LiteralPath $GoogleServicesJson -Destination $androidOutputPath
Write-Output 'Created ignored Dart and Android client config for muenee-pj / com.muenee.app.'
