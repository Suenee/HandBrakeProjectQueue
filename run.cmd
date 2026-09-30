@echo off
setlocal
set "APP=%~dp0bin\HandBrakeProjectQueue.exe"
if not exist "%APP%" (
  echo ERROR: HandBrake Project Queue is not built. Run upgrade.cmd first.
  exit /b 1
)
start "" "%APP%"
exit /b 0
