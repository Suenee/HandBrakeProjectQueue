@echo off
setlocal
pushd "%~dp0" || exit /b 1
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0src\HandBrakeProjectQueue.ps1"
set "RC=%ERRORLEVEL%"
popd
exit /b %RC%
