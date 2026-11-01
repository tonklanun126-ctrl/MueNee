$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'use_local_toolchain.ps1')
$jdk21 = Get-ChildItem -LiteralPath (Join-Path $mueneeTooling 'jdk') -Directory -Filter 'jdk-21*' | Sort-Object Name -Descending | Select-Object -First 1
if ($null -eq $jdk21) { throw 'Firebase CLI 15 requires Java 21. Install it in the sibling .tooling/jdk directory.' }
$env:JAVA_HOME = $jdk21.FullName
$env:PATH = "$env:JAVA_HOME\bin;$env:PATH"
$env:_JAVA_OPTIONS = '-Xmx512m -XX:MaxMetaspaceSize=192m -XX:ActiveProcessorCount=2'
$env:DEBUG = $null
Push-Location (Split-Path -Parent $PSScriptRoot)
try {
    & npm.cmd run seed:emulator
    if ($LASTEXITCODE -ne 0) { throw "Seed emulator test failed with exit code $LASTEXITCODE." }
}
finally { Pop-Location }
