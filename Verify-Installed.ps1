#requires -Version 5.1
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$package = Get-AppxPackage -Name 'Eventide.Banpilot'
if (-not $package) { throw 'Install the app before running this check.' }
Add-Type -AssemblyName System.Runtime.WindowsRuntime
$catalog = [Windows.ApplicationModel.AppExtensions.AppExtensionCatalog,Windows.ApplicationModel.AppExtensions,ContentType=WindowsRuntime]::Open('com.microsoft.windows.copilotkeyprovider')
$operation = $catalog.FindAllAsync()
$asTask = [System.WindowsRuntimeSystemExtensions].GetMethods() | Where-Object {
    $_.Name -eq 'AsTask' -and $_.IsGenericMethod -and $_.GetGenericArguments().Count -eq 1 -and
    $_.GetParameters().Count -eq 1 -and $_.GetParameters()[0].ParameterType.Name -eq 'IAsyncOperation`1'
} | Select-Object -First 1
$resultType = [System.Collections.Generic.IReadOnlyList[Windows.ApplicationModel.AppExtensions.AppExtension]]
$task = $asTask.MakeGenericMethod($resultType).Invoke($null, @($operation))
if (-not $task.Wait(10000)) { throw 'App extension discovery timed out.' }
$extension = @($task.Result | Where-Object { $_.Package.Id.Name -eq 'Eventide.Banpilot' })
if ($extension.Count -ne 1) { throw 'Copilot provider registration was not discovered.' }
Write-Output ('Registered provider: ' + $extension[0].DisplayName)
Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;
[ComImport, Guid("2e941141-7f97-4756-ba1d-9decde894a3d"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
interface INoOpActivationManager {
    [PreserveSig] int ActivateApplication([MarshalAs(UnmanagedType.LPWStr)] string appId,
        [MarshalAs(UnmanagedType.LPWStr)] string arguments, uint options, out uint processId);
}
public static class NoOpActivationCheck {
    [DllImport("user32.dll")] public static extern IntPtr GetForegroundWindow();
    public static uint Activate(string appId) {
        object instance = Activator.CreateInstance(Type.GetTypeFromCLSID(new Guid("45BA127D-10A8-46EA-8AB7-56EA9078943C")));
        try {
            uint pid;
            int hr = ((INoOpActivationManager)instance).ActivateApplication(appId, "", 0, out pid);
            Marshal.ThrowExceptionForHR(hr);
            return pid;
        } finally { Marshal.ReleaseComObject(instance); }
    }
}
'@
$aumid = $package.PackageFamilyName + '!App'
$results = @(1..5 | ForEach-Object {
    $foreground = [NoOpActivationCheck]::GetForegroundWindow()
    $timer = [Diagnostics.Stopwatch]::StartNew()
    $activatedProcessId = [NoOpActivationCheck]::Activate($aumid)
    $process = Get-Process -Id $activatedProcessId -ErrorAction SilentlyContinue
    if ($process -and -not $process.WaitForExit(5000)) { throw 'Activated app did not exit.' }
    $timer.Stop()
    [pscustomobject]@{ run=$_; processId=$activatedProcessId; elapsedMs=$timer.ElapsedMilliseconds; foregroundUnchanged=($foreground -eq [NoOpActivationCheck]::GetForegroundWindow()) }
})
if (Get-Process -Name Banpilot -ErrorAction SilentlyContinue) { throw 'Unexpected resident app process.' }
$results | Format-Table
$results | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $PSScriptRoot 'out\activation-test.json') -Encoding UTF8
Write-Output ('AUMID: ' + $aumid)
