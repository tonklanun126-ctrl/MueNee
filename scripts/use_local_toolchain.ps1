# Dot-source this file in PowerShell: . .\scripts\use_local_toolchain.ps1
# Optional convenience for this checkout; other machines can use their own SDKs.
$mueneeTooling = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..\.tooling'))
if (-not (Test-Path -LiteralPath (Join-Path $mueneeTooling 'flutter\bin\flutter.bat'))) {
    throw 'Sibling .tooling Flutter SDK not found. Configure your installed Flutter/Android SDK instead.'
}
$env:JAVA_HOME = Join-Path $mueneeTooling 'jdk\jdk-17.0.20.1+1'
$env:ANDROID_HOME = Join-Path $mueneeTooling 'android-sdk'
$env:ANDROID_SDK_ROOT = $env:ANDROID_HOME
$env:ANDROID_USER_HOME = Join-Path $mueneeTooling 'android-user-home'
$env:GRADLE_USER_HOME = Join-Path $mueneeTooling 'gradle-home'
$env:PUB_CACHE = Join-Path $mueneeTooling 'pub-cache'
$env:LOCALAPPDATA = Join-Path $mueneeTooling 'localappdata'
$env:APPDATA = Join-Path $mueneeTooling 'appdata'
$env:DART_TOOL_HOME = Join-Path $mueneeTooling 'dart-tool-home'
$env:npm_config_cache = Join-Path $mueneeTooling 'npm-cache'
$env:FIREBASE_EMULATORS_PATH = Join-Path $mueneeTooling 'firebase-emulators'
$env:PATH = "$mueneeTooling\bin;$mueneeTooling\flutter\bin;$env:JAVA_HOME\bin;$env:ANDROID_HOME\platform-tools;$env:PATH"
