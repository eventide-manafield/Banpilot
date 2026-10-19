#requires -Version 5.1
[CmdletBinding()]
param([string]$ReleaseDirectory)
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
if ([string]::IsNullOrWhiteSpace($ReleaseDirectory)) {
    $ReleaseDirectory = [IO.File]::ReadAllText((Join-Path $PSScriptRoot 'out\latest.txt')).Trim()
}
$release = (Resolve-Path -LiteralPath $ReleaseDirectory).Path
$build = Get-Content -LiteralPath (Join-Path $release 'build.json') -Raw | ConvertFrom-Json
if ($build.version -notmatch '\A\d+\.\d+\.\d+\z' -or $build.package -ne ('Banpilot-' + $build.version + '-x64.msix')) { throw 'Unexpected release metadata.' }
& (Join-Path $PSScriptRoot 'Install.ps1') -ReleaseDirectory $release -CheckOnly
if ($LASTEXITCODE -ne 0) { throw 'Package verification failed.' }
# Explicit allowlist: no private keys, compiler output or local diagnostics.
$names = @('Install.bat','Install.cmd','Install.ps1','INSTALL.txt','README.md','build.json','Banpilot.cer',$build.package)
$files = @($names | ForEach-Object {
    $path = Join-Path $release $_
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { throw "Missing release file: $_" }
    $path
})
$zip = Join-Path $release ('Banpilot-' + $build.version + '-windows-x64.zip')
if (Test-Path -LiteralPath $zip) { throw "Archive already exists: $zip" }
Compress-Archive -LiteralPath $files -DestinationPath $zip -CompressionLevel Optimal
$hash = (Get-FileHash -LiteralPath $zip -Algorithm SHA256).Hash.ToLowerInvariant()
[IO.File]::WriteAllText((Join-Path $release 'SHA256SUMS.txt'), ($hash + '  ' + [IO.Path]::GetFileName($zip) + "`r`n"), [Text.Encoding]::ASCII)
Write-Output "Release archive: $zip"
