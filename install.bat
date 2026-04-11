@echo off
:: ============================================================
:: install.bat — Windows installer launcher for offlineAI
::
:: Double-click this file or run it from a terminal in the
:: repo root to install and set up the local offline AI app.
::
:: Usage:
::   install.bat                  (use default model: qwen2.5:3b)
::   install.bat qwen2.5:7b       (specify a different model)
:: ============================================================

setlocal

:: Determine the directory this .bat file lives in (repo root).
set "SCRIPT_DIR=%~dp0"

:: Accept an optional model name as the first argument.
if "%~1"=="" (
    set "MODEL_ARG="
) else (
    set "MODEL_ARG=-Model %~1"
)

:: Launch the PowerShell installer with ExecutionPolicy Bypass so it
:: runs even if the user has not changed their execution policy.
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%install.ps1" %MODEL_ARG%

:: Preserve the exit code from PowerShell.
set "PS_EXIT=%ERRORLEVEL%"

if %PS_EXIT% neq 0 (
    echo.
    echo Installation failed with exit code %PS_EXIT%.
    echo See the messages above for details.
    pause
)

endlocal
exit /b %PS_EXIT%
