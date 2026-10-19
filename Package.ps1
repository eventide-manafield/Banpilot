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
$setup = Join-Path $release ('Banpilot-' + $build.version + '-Setup-x64.exe')
$csc = Join-Path $env:windir 'Microsoft.NET\Framework64\v4.0.30319\csc.exe'
$resources = @('Install.ps1','build.json','Banpilot.cer',$build.package) | ForEach-Object {
    '/resource:"' + (Join-Path $release $_) + '",' + $_
}
& $csc /nologo /target:exe /platform:x64 /optimize+ "/out:$setup" $resources (Join-Path $PSScriptRoot 'Setup.cs')
if ($LASTEXITCODE -ne 0) { throw 'Setup compilation failed.' }
$signTool = Join-Path ${env:ProgramFiles(x86)} 'Windows Kits\10\bin\10.0.26100.0\x64\signtool.exe'
& $signTool sign /fd SHA256 /s My /sha1 $build.certificateThumbprint $setup
if ($LASTEXITCODE -ne 0) { throw 'Setup signing failed.' }
$signature = Get-AuthenticodeSignature -LiteralPath $setup
if (-not $signature.SignerCertificate -or $signature.SignerCertificate.Thumbprint -ne $build.certificateThumbprint) { throw 'Unexpected setup signer.' }
Compress-Archive -LiteralPath $files -DestinationPath $zip -CompressionLevel Optimal
$checksums = foreach ($asset in @($setup,$zip)) {
    (Get-FileHash -LiteralPath $asset -Algorithm SHA256).Hash.ToLowerInvariant() + '  ' + [IO.Path]::GetFileName($asset)
}
[IO.File]::WriteAllText((Join-Path $release 'SHA256SUMS.txt'), (($checksums -join "`r`n") + "`r`n"), [Text.Encoding]::ASCII)
Write-Output "Standalone installer: $setup"
Write-Output "Release archive: $zip"
