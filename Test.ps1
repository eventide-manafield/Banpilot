#requires -Version 5.1
$ErrorActionPreference = 'Stop'
$output = Join-Path $PSScriptRoot 'out\tests'
[IO.Directory]::CreateDirectory($output) | Out-Null
$runner = Join-Path $output 'WindowsKeyTapTests.exe'
$csc = Join-Path $env:windir 'Microsoft.NET\Framework64\v4.0.30319\csc.exe'
& $csc /nologo /target:exe /platform:x64 /main:WindowsKeyTapTests "/out:$runner" (Join-Path $PSScriptRoot 'WindowsKeyTap.cs') (Join-Path $PSScriptRoot 'tests\WindowsKeyTapTests.cs')
if ($LASTEXITCODE -ne 0) { throw 'Test compilation failed.' }
& $runner
if ($LASTEXITCODE -ne 0) { throw 'Windows-key logic tests failed.' }
[xml]$manifest = Get-Content -Raw -LiteralPath (Join-Path $PSScriptRoot 'AppxManifest.xml')
$apps = @($manifest.Package.Applications.Application)
if ($apps.Count -ne 2 -or $apps[0].Id -ne 'App' -or $apps[1].Id -ne 'WindowsKey') { throw 'Expected preserved no-op identity and separate Windows-key app.' }
foreach ($app in $apps) {
    if ($app.Extensions.Extension.AppExtension.Name -ne 'com.microsoft.windows.copilotkeyprovider') { throw 'Missing Copilot provider.' }
}
Write-Output 'Manifest: two separate Copilot provider app entries; original App identity preserved.'
