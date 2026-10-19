@echo off
rem Double-click this file after extracting the release ZIP.
call "%~dp0Install.cmd" %*
exit /b %errorlevel%
