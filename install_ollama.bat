@echo off
setlocal enabledelayedexpansion

:: ============================================================
::  install_ollama.bat
::  Checks for Ollama and silently installs it if missing.
::  Uses winget first; falls back to downloading the EXE.
:: ============================================================

echo [Ollama] Checking for Ollama...

where ollama >nul 2>&1
if %errorlevel% == 0 (
    for /f "tokens=*" %%v in ('ollama --version 2^>^&1') do set OLLAMA_VER=%%v
    echo [Ollama] Found Ollama !OLLAMA_VER! — no install needed.
    exit /b 0
)

:: Also check the default install location on Windows.
if exist "%LOCALAPPDATA%\Programs\Ollama\ollama.exe" (
    echo [Ollama] Found Ollama at %LOCALAPPDATA%\Programs\Ollama\ — no install needed.
    set "PATH=%LOCALAPPDATA%\Programs\Ollama;%PATH%"
    exit /b 0
)

echo [Ollama] Ollama not found. Attempting silent install...

:: ── Try winget ──────────────────────────────────────────────
where winget >nul 2>&1
if %errorlevel% == 0 (
    echo [Ollama] Installing Ollama via winget...
    winget install --id Ollama.Ollama -e --silent --accept-package-agreements --accept-source-agreements
    if !errorlevel! == 0 (
        echo [Ollama] winget install succeeded.
        goto :refresh_path
    )
    echo [Ollama] winget install returned !errorlevel! — trying EXE fallback...
)

:: ── Fallback: download the official Windows installer ───────
echo [Ollama] Downloading Ollama Windows installer...

set OLLAMA_EXE=%TEMP%\OllamaSetup.exe
set OLLAMA_URL=https://ollama.com/download/OllamaSetup.exe

powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "try { [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12; (New-Object System.Net.WebClient).DownloadFile('%OLLAMA_URL%', '%OLLAMA_EXE%'); exit 0 } catch { Write-Host ('Download error: ' + $_.Exception.Message); exit 1 }"

if %errorlevel% neq 0 (
    echo [Ollama] ERROR: Could not download Ollama installer.
    echo          Please install Ollama manually from https://ollama.com/download
    exit /b 1
)

echo [Ollama] Running silent installer (may require admin)...
"%OLLAMA_EXE%" /S
if %errorlevel% neq 0 (
    echo [Ollama] ERROR: Installer failed ^(code %errorlevel%^).
    echo          Please run it manually: %OLLAMA_EXE%
    exit /b 1
)

del /q "%OLLAMA_EXE%" 2>nul

:refresh_path
:: Reload PATH so ollama is available in the current session.
for /f "usebackq tokens=2*" %%A in (
    `reg query "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" /v Path 2^>nul`
) do set "SYS_PATH=%%B"
for /f "usebackq tokens=2*" %%A in (
    `reg query "HKCU\Environment" /v Path 2^>nul`
) do set "USR_PATH=%%B"
set "PATH=%SYS_PATH%;%USR_PATH%;%PATH%"

:: Also add the known default Ollama install path.
if exist "%LOCALAPPDATA%\Programs\Ollama" (
    set "PATH=%LOCALAPPDATA%\Programs\Ollama;%PATH%"
)

where ollama >nul 2>&1
if %errorlevel% neq 0 (
    echo [Ollama] WARNING: ollama still not found on PATH after install.
    echo          You may need to open a new command prompt.
    exit /b 1
)

for /f "tokens=*" %%v in ('ollama --version 2^>^&1') do set OLLAMA_VER=%%v
echo [Ollama] Ollama !OLLAMA_VER! is ready.
exit /b 0
