@echo off
setlocal EnableExtensions DisableDelayedExpansion
cls
set "REPO=%~dp0"
if "%REPO:~-1%"=="\\" set "REPO=%REPO:~0,-1%"
set "TMP_LAUNCH=%TEMP%\\HBPQ_upgrade_%RANDOM%_%RANDOM%.cmd"
copy /y "%~f0" "%TMP_LAUNCH%" >nul || exit /b 1
if /I "%~1"=="--temp" goto TEMP
call "%TMP_LAUNCH%" --temp "%REPO%"
exit /b %ERRORLEVEL%
:TEMP
set "REPO=%~2"
if not defined REPO exit /b 2
pushd "%REPO%" || exit /b 3
if not exist .git (echo ERROR: This bootstrap requires an existing checkout in v0.01.& popd & exit /b 4)
git.exe fetch origin main || (popd & exit /b 5)
for /f "delims=" %%F in ('git.exe show origin/main:upgrade.ps1') do >>"%TEMP%\\HBPQ_upgrade.ps1" echo(%%F
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%TEMP%\\HBPQ_upgrade.ps1" -RepositoryPath "%REPO%"
set "RC=%ERRORLEVEL%"
del /q "%TEMP%\\HBPQ_upgrade.ps1" >nul 2>nul
popd
exit /b %RC%
