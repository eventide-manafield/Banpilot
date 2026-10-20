#requires -Version 5.1
[CmdletBinding()]
param()
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
if ($PSVersionTable.PSEdition -ne 'Desktop') { throw 'Use Windows PowerShell 5.1.' }
$kits = Join-Path ${env:ProgramFiles(x86)} 'Windows Kits\10\bin\10.0.26100.0\x64'
$csc = Join-Path $env:windir 'Microsoft.NET\Framework64\v4.0.30319\csc.exe'
[xml]$manifest = Get-Content -LiteralPath (Join-Path $PSScriptRoot 'AppxManifest.xml') -Raw
$packageVersion = [version]$manifest.Package.Identity.Version
$version = '{0}.{1}.{2}' -f $packageVersion.Major,$packageVersion.Minor,$packageVersion.Build
$packageName = 'Banpilot-' + $version + '-x64.msix'
$output = Join-Path $PSScriptRoot ('out\' + [guid]::NewGuid().ToString('N'))
$payload = Join-Path $output 'payload'
[IO.Directory]::CreateDirectory((Join-Path $payload 'Assets')) | Out-Null
[IO.Directory]::CreateDirectory((Join-Path $payload 'Public')) | Out-Null
[IO.File]::WriteAllText((Join-Path $payload 'Public\provider.txt'), 'Copilot No-op provider')
Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'AppxManifest.xml') -Destination $payload
Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'LICENSE') -Destination $payload
& $csc /nologo /target:winexe /platform:x64 /optimize+ "/out:$payload\Banpilot.exe" (Join-Path $PSScriptRoot 'Banpilot.cs')
if ($LASTEXITCODE -ne 0) { throw 'Compilation failed.' }
& $csc /nologo /target:winexe /platform:x64 /optimize+ "/out:$payload\Banpilot.WindowsKey.exe" (Join-Path $PSScriptRoot 'WindowsKeyTap.cs')
if ($LASTEXITCODE -ne 0) { throw 'Windows-key app compilation failed.' }
Add-Type -AssemblyName System.Drawing
foreach ($entry in @(@('StoreLogo',50),@('Square44x44Logo',44),@('Square150x150Logo',150))) {
    $size = [int]$entry[1]
    $bitmap = New-Object Drawing.Bitmap($size,$size)
    $graphics = [Drawing.Graphics]::FromImage($bitmap)
    $pen = New-Object Drawing.Pen([Drawing.Color]::White, [single]($size / 12))
    try {
        $graphics.Clear([Drawing.Color]::FromArgb(49,57,72))
        $graphics.DrawLine($pen, [single]($size*.27), [single]($size*.5), [single]($size*.73), [single]($size*.5))
        $bitmap.Save((Join-Path $payload ('Assets\' + $entry[0] + '.png')))
    } finally { $pen.Dispose(); $graphics.Dispose(); $bitmap.Dispose() }
}
$savedThumb = Join-Path $PSScriptRoot 'out\certificate-thumbprint.txt'
$certificate = $null
if (Test-Path -LiteralPath $savedThumb) {
    $thumb = [IO.File]::ReadAllText($savedThumb).Trim()
    if ($thumb -notmatch '\A[0-9A-F]{40}\z') { throw 'Invalid certificate thumbprint.' }
    $certificate = Get-Item -LiteralPath "Cert:\CurrentUser\My\$thumb" -ErrorAction SilentlyContinue
}
if (-not $certificate) {
    $certificate = New-SelfSignedCertificate -Type Custom -Subject 'CN=Eventide Banpilot Test' `
        -KeyUsage DigitalSignature -KeyAlgorithm RSA -KeyLength 2048 -HashAlgorithm SHA256 `
        -KeyExportPolicy NonExportable -CertStoreLocation 'Cert:\CurrentUser\My' `
        -TextExtension @('2.5.29.37={text}1.3.6.1.5.5.7.3.3','2.5.29.19={text}') -NotAfter (Get-Date).AddYears(2)
    [IO.File]::WriteAllText($savedThumb, $certificate.Thumbprint)
}
if (-not $certificate.HasPrivateKey -or $certificate.NotAfter -le (Get-Date)) { throw 'A valid local signing key is required.' }
Export-Certificate -Cert $certificate -FilePath (Join-Path $output 'Banpilot.cer') | Out-Null
$msix = Join-Path $output $packageName
& (Join-Path $kits 'makeappx.exe') pack /d $payload /p $msix
if ($LASTEXITCODE -ne 0) { throw 'MSIX packaging failed.' }
& (Join-Path $kits 'signtool.exe') sign /fd SHA256 /s My /sha1 $certificate.Thumbprint $msix
if ($LASTEXITCODE -ne 0) { throw 'MSIX signing failed.' }
$signature = Get-AuthenticodeSignature -LiteralPath $msix
if (-not $signature.SignerCertificate -or $signature.SignerCertificate.Thumbprint -ne $certificate.Thumbprint) { throw 'Unexpected package signer.' }
[ordered]@{
    package=$packageName; version=$version; packageVersion=$packageVersion.ToString(); sha256=(Get-FileHash -LiteralPath $msix).Hash
    certificateThumbprint=$certificate.Thumbprint; builtUtc=[DateTime]::UtcNow.ToString('o')
} | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $output 'build.json') -Encoding UTF8
foreach ($file in @('Install.bat', 'Install.cmd', 'Install.ps1', 'INSTALL.txt', 'README.md', 'LICENSE')) {
    Copy-Item -LiteralPath (Join-Path $PSScriptRoot $file) -Destination $output
}
[IO.File]::WriteAllText((Join-Path $PSScriptRoot 'out\latest.txt'), $output)
Write-Output "Built (not installed): $output"
