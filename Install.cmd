@echo off
setlocal
title Eventide's Banpilot Installer
rem Use the Windows PowerShell modules even when launched from PowerShell 7.
set "PSModulePath=%SystemRoot%\System32\WindowsPowerShell\v1.0\Modules"
set "pauseOption="
if "%~1"=="" set "pauseOption=-PauseOnExit"
"%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -ExecutionPolicy Bypass -File "%~dp0Install.ps1" %* %pauseOption%
set "installExit=%errorlevel%"
exit /b %installExit%
