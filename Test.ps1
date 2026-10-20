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

$resources = @('en-US','ko-KR') | ForEach-Object {
    '/resource:"' + (Join-Path $PSScriptRoot "Strings\$_\Resources.resw") + '",' + $_ + '.resw'
}
$localizationRunner = Join-Path $output 'LocalizationTests.exe'
& $csc /nologo /target:exe /platform:x64 /main:LocalizationTests "/out:$localizationRunner" $resources (Join-Path $PSScriptRoot 'InstallerText.cs') (Join-Path $PSScriptRoot 'tests\LocalizationTests.cs')
if ($LASTEXITCODE -ne 0) { throw 'Localization test compilation failed.' }
& $localizationRunner
if ($LASTEXITCODE -ne 0) { throw 'Localization tests failed.' }
[xml]$english = Get-Content -Raw -Encoding UTF8 (Join-Path $PSScriptRoot 'Strings\en-US\Resources.resw')
[xml]$korean = Get-Content -Raw -Encoding UTF8 (Join-Path $PSScriptRoot 'Strings\ko-KR\Resources.resw')
if (Compare-Object @($english.root.data.name | Sort-Object) @($korean.root.data.name | Sort-Object)) { throw 'Language resource keys differ.' }
foreach ($language in @($english,$korean)) {
    if (@($language.root.data | Group-Object name | Where-Object Count -ne 1).Count) { throw 'Duplicate resource key.' }
    foreach ($entry in $language.root.data) { if ([string]::IsNullOrWhiteSpace([string]$entry.value)) { throw 'Empty translated string.' } }
}
foreach ($reference in [regex]::Matches($manifest.OuterXml, 'ms-resource:([A-Za-z]+)')) {
    if ($reference.Groups[1].Value -notin $english.root.data.name) { throw 'Unresolved manifest string.' }
}
Write-Output 'Localization: matching translation keys and all manifest resource references verified.'
