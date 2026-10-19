#requires -Version 5.1
[CmdletBinding()]
param([string]$ReleaseDirectory, [switch]$TrustOnly, [switch]$CheckOnly)
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
# Windows PowerShell 5.1 can evaluate advanced-script parameter defaults before
# PSScriptRoot is populated. Resolve the default in the script body instead.
if ([string]::IsNullOrWhiteSpace($ReleaseDirectory)) { $ReleaseDirectory = $PSScriptRoot }
if ($CheckOnly -and $TrustOnly) { throw 'CheckOnly cannot be combined with TrustOnly.' }
$release = (Resolve-Path -LiteralPath $ReleaseDirectory).Path
$build = Get-Content -LiteralPath (Join-Path $release 'build.json') -Raw | ConvertFrom-Json
$package = Join-Path $release 'Banpilot-0.2.0-x64.msix'
$publicCertificate = Join-Path $release 'Banpilot.cer'
$certificate = New-Object Security.Cryptography.X509Certificates.X509Certificate2($publicCertificate)
if ($certificate.Subject -ne 'CN=Eventide Banpilot Test' -or $certificate.Thumbprint -ne $build.certificateThumbprint) { throw 'Unexpected app certificate.' }
if ((Get-FileHash -LiteralPath $package).Hash -ne $build.sha256) { throw 'Package hash mismatch.' }
$signature = Get-AuthenticodeSignature -LiteralPath $package
if (-not $signature.SignerCertificate -or $signature.SignerCertificate.Thumbprint -ne $certificate.Thumbprint) { throw 'Unexpected package signer.' }
$trustPath = 'Cert:\LocalMachine\TrustedPeople\' + $certificate.Thumbprint
if ($CheckOnly) {
    [pscustomobject]@{ releaseDirectory=$release; packageHashVerified=$true; certificateThumbprint=$certificate.Thumbprint; certificateTrusted=(Test-Path -LiteralPath $trustPath); signatureStatus=[string]$signature.Status } | ConvertTo-Json
    exit 0
}
if ($TrustOnly) {
    if (-not (Test-Path -LiteralPath $trustPath)) {
        Import-Certificate -FilePath $publicCertificate -CertStoreLocation 'Cert:\LocalMachine\TrustedPeople' | Out-Null
        @{ certificateThumbprint=$certificate.Thumbprint; store='LocalMachine\TrustedPeople'; addedByInstaller=$true } |
            ConvertTo-Json | Set-Content -LiteralPath (Join-Path $release 'certificate-trust.json') -Encoding UTF8
    }
    exit 0
}
if (-not (Test-Path -LiteralPath $trustPath)) {
    $arguments = '-NoProfile -ExecutionPolicy Bypass -File "' + $PSCommandPath + '" -ReleaseDirectory "' + $release + '" -TrustOnly'
    $process = Start-Process -FilePath (Join-Path $env:windir 'System32\WindowsPowerShell\v1.0\powershell.exe') `
        -Verb RunAs -WindowStyle Hidden -ArgumentList $arguments -PassThru
    $process.WaitForExit()
    if ($process.ExitCode -ne 0 -or -not (Test-Path -LiteralPath $trustPath)) { throw 'App certificate trust was not completed.' }
}
if ((Get-AuthenticodeSignature -LiteralPath $package).Status -ne 'Valid') { throw 'Package signature is not valid after trust installation.' }
Add-AppxPackage -Path $package
$installed = Get-AppxPackage -Name 'Eventide.Banpilot'
if (-not $installed -or $installed.Publisher -ne $certificate.Subject) { throw 'App installation was not confirmed.' }
$installed | Select-Object Name,Version,PackageFamilyName,InstallLocation,Status | Format-List
Write-Output 'Installed. Select this app in Windows Settings to assign the Copilot key. No boot or driver settings were changed.'
