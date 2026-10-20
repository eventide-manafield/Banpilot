#requires -Version 5.1
[CmdletBinding()]
param([string]$ReleaseDirectory, [switch]$TrustOnly, [switch]$CheckOnly, [switch]$PauseOnExit)
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
[Console]::OutputEncoding = New-Object Text.UTF8Encoding($false)
$messages = @{}
function Get-Text([string]$Key) { return $messages[$Key] }
try {
# Windows PowerShell 5.1 can evaluate advanced-script parameter defaults before
# PSScriptRoot is populated. Resolve the default in the script body instead.
if ([string]::IsNullOrWhiteSpace($ReleaseDirectory)) { $ReleaseDirectory = $PSScriptRoot }
$release = (Resolve-Path -LiteralPath $ReleaseDirectory).Path
$language = if ([Globalization.CultureInfo]::CurrentUICulture.TwoLetterISOLanguageName -eq 'ko') { 'ko-KR' } else { 'en-US' }
[xml]$strings = Get-Content -LiteralPath (Join-Path $release ($language + '.resw')) -Raw -Encoding UTF8
foreach ($entry in $strings.root.data) { $messages[$entry.name] = [string]$entry.value }
if ($CheckOnly -and $TrustOnly) { throw (Get-Text 'InvalidSwitches') }
$build = Get-Content -LiteralPath (Join-Path $release 'build.json') -Raw | ConvertFrom-Json
if ($build.package -notmatch '\ABanpilot-\d+\.\d+\.\d+-x64\.msix\z') { throw (Get-Text 'UnexpectedFilename') }
$package = Join-Path $release $build.package
$publicCertificate = Join-Path $release 'Banpilot.cer'
$certificate = New-Object Security.Cryptography.X509Certificates.X509Certificate2($publicCertificate)
if ($certificate.Subject -ne 'CN=Eventide Banpilot Test' -or $certificate.Thumbprint -ne $build.certificateThumbprint) { throw (Get-Text 'UnexpectedCertificate') }
if ((Get-FileHash -LiteralPath $package).Hash -ne $build.sha256) { throw (Get-Text 'HashMismatch') }
$signature = Get-AuthenticodeSignature -LiteralPath $package
if (-not $signature.SignerCertificate -or $signature.SignerCertificate.Thumbprint -ne $certificate.Thumbprint) { throw (Get-Text 'UnexpectedSigner') }
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
    if ($process.ExitCode -ne 0 -or -not (Test-Path -LiteralPath $trustPath)) { throw (Get-Text 'TrustFailed') }
}
if ((Get-AuthenticodeSignature -LiteralPath $package).Status -ne 'Valid') { throw (Get-Text 'InvalidSignature') }
Add-AppxPackage -Path $package
$installed = Get-AppxPackage -Name 'Eventide.Banpilot'
if (-not $installed -or $installed.Publisher -ne $certificate.Subject) { throw (Get-Text 'InstallNotConfirmed') }
if ([string]$installed.Version -ne [string]$build.packageVersion) { throw (Get-Text 'VersionMismatch') }
$installed | Select-Object Name,Version,PackageFamilyName,InstallLocation,Status | Format-List
Write-Output (Get-Text 'Installed')
Write-Output ('  ' + (Get-Text 'NoOpDisplayName'))
Write-Output ('  ' + (Get-Text 'WindowsKeyDisplayName'))
} catch {
    $prefix = if ($messages.ContainsKey('ErrorPrefix')) { Get-Text 'ErrorPrefix' } else { 'Installation error: ' }
    Write-Host ($prefix + $_.Exception.Message) -ForegroundColor Red
    exit 1
} finally {
    if ($PauseOnExit) {
        $prompt = if ($messages.ContainsKey('ClosePrompt')) { Get-Text 'ClosePrompt' } else { 'Press Enter to close this window.' }
        Write-Host $prompt
        [void][Console]::ReadLine()
    }
}
