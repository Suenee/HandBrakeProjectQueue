@echo off
setlocal EnableExtensions DisableDelayedExpansion
if /I "%~1"=="--hbpq-temp" goto :TEMP
cls
set "HBPQ_REPO=%~dp0"
if "%HBPQ_REPO:~-1%"=="\" set "HBPQ_REPO=%HBPQ_REPO:~0,-1%"
set "HBPQ_TMP=%TEMP%\HBPQ_upgrade_%RANDOM%_%RANDOM%.cmd"
copy /y "%~f0" "%HBPQ_TMP%" >nul || exit /b 1
call "%HBPQ_TMP%" --hbpq-temp "%HBPQ_REPO%"
set "HBPQ_RC=%ERRORLEVEL%"
del /q "%HBPQ_TMP%" >nul 2>nul
exit /b %HBPQ_RC%

:TEMP
set "HBPQ_REPO=%~2"
if not defined HBPQ_REPO exit /b 2
where git.exe >nul 2>nul || (
  echo ERROR: Git is required. Install Git for Windows and run upgrade.cmd again.
  exit /b 3
)
pushd "%HBPQ_REPO%" || exit /b 4

if not exist ".git" (
  echo [BOOTSTRAP] Preparing fresh checkout...
  for /f "delims=" %%F in ('dir /b /a 2^>nul') do (
    if /I not "%%F"=="upgrade.cmd" if /I not "%%F"=="logs" (
      echo ERROR: Fresh bootstrap target is not empty: %%F
      popd
      exit /b 5
    )
  )
  git.exe init . || (popd & exit /b 6)
  git.exe remote add origin https://github.com/Suenee/HandBrakeProjectQueue.git || (popd & exit /b 7)
  git.exe fetch origin main || (popd & exit /b 8)
  git.exe ls-files --error-unmatch upgrade.cmd >nul 2>nul
  if errorlevel 1 del /q "upgrade.cmd" >nul 2>nul
  git.exe checkout -B main origin/main || (popd & exit /b 9)
) else (
  git.exe remote get-url origin >nul 2>nul || git.exe remote add origin https://github.com/Suenee/HandBrakeProjectQueue.git
  git.exe fetch origin main || (popd & exit /b 10)
)

set "HBPQ_PS=%TEMP%\HBPQ_upgrade_%RANDOM%_%RANDOM%.ps1"
git.exe show origin/main:upgrade.ps1 > "%HBPQ_PS%"
if errorlevel 1 (del /q "%HBPQ_PS%" >nul 2>nul & popd & exit /b 11)
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%HBPQ_PS%" -RepositoryPath "%HBPQ_REPO%"
set "HBPQ_RC=%ERRORLEVEL%"
del /q "%HBPQ_PS%" >nul 2>nul
popd
exit /b %HBPQ_RC%
