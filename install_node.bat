@echo off
setlocal enabledelayedexpansion

:: ============================================================
::  install_node.bat
::  Checks for Node.js and silently installs it if missing.
::  Uses winget first; falls back to downloading the MSI.
:: ============================================================

echo [Node] Checking for Node.js...

where node >nul 2>&1
if %errorlevel% == 0 (
    for /f "tokens=*" %%v in ('node --version 2^>^&1') do set NODE_VER=%%v
    echo [Node] Found Node.js !NODE_VER! — no install needed.
    exit /b 0
)

echo [Node] Node.js not found. Attempting silent install...

:: ── Try winget ──────────────────────────────────────────────
where winget >nul 2>&1
if %errorlevel% == 0 (
    echo [Node] Installing Node.js LTS via winget...
    winget install --id OpenJS.NodeJS.LTS -e --silent --accept-package-agreements --accept-source-agreements
    if !errorlevel! == 0 (
        echo [Node] winget install succeeded.
        goto :refresh_path
    )
    echo [Node] winget install returned !errorlevel! — trying MSI fallback...
)

:: ── Fallback: download the official LTS MSI via PowerShell ──
echo [Node] Downloading Node.js LTS MSI installer...

set NODE_MSI=%TEMP%\node_lts_installer.msi
set NODE_MSI_URL=https://nodejs.org/dist/latest-v20.x/node-v20.19.0-x64.msi

powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "try { [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12; (New-Object System.Net.WebClient).DownloadFile('%NODE_MSI_URL%', '%NODE_MSI%'); exit 0 } catch { Write-Host ('Download error: ' + $_.Exception.Message); exit 1 }"

if %errorlevel% neq 0 (
    echo [Node] ERROR: Could not download Node.js installer.
    echo         Please install Node.js manually from https://nodejs.org/
    exit /b 1
)

echo [Node] Running silent MSI install (may require admin)...
msiexec /i "%NODE_MSI%" /qn /norestart ADDLOCAL=ALL
if %errorlevel% neq 0 (
    echo [Node] ERROR: MSI install failed ^(code %errorlevel%^).
    echo         Please run the installer manually: %NODE_MSI%
    exit /b 1
)

del /q "%NODE_MSI%" 2>nul

:refresh_path
:: Reload PATH so node is available in the current session.
for /f "usebackq tokens=2*" %%A in (
    `reg query "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" /v Path 2^>nul`
) do set "SYS_PATH=%%B"
for /f "usebackq tokens=2*" %%A in (
    `reg query "HKCU\Environment" /v Path 2^>nul`
) do set "USR_PATH=%%B"
set "PATH=%SYS_PATH%;%USR_PATH%;%PATH%"

where node >nul 2>&1
if %errorlevel% neq 0 (
    echo [Node] WARNING: node still not found on PATH after install.
    echo         You may need to open a new command prompt.
    exit /b 1
)

for /f "tokens=*" %%v in ('node --version 2^>^&1') do set NODE_VER=%%v
echo [Node] Node.js !NODE_VER! is ready.
exit /b 0
