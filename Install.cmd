@echo off
setlocal
title Eventide's Banpilot Installer
rem Use the Windows PowerShell modules even when launched from PowerShell 7.
set "PSModulePath=%SystemRoot%\System32\WindowsPowerShell\v1.0\Modules"
"%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -ExecutionPolicy Bypass -File "%~dp0Install.ps1" %*
set "installExit=%errorlevel%"
if not "%installExit%"=="0" echo Installation failed. See the error above.
if "%~1"=="" pause
exit /b %installExit%
