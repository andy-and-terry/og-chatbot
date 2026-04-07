@echo off
setlocal enabledelayedexpansion

:: ============================================================
::  start.bat
::  The OG Chatbot — single-click launcher for Windows.
::
::  What this script does:
::    1. Silently installs / verifies Node.js  (install_node.bat)
::    2. Silently installs / verifies Ollama   (install_ollama.bat)
::    3. Ensures Ollama service is running
::    4. Starts the Node.js chat server (server.js) and opens the UI
:: ============================================================

:: Change to the directory where this script lives so relative
:: paths to the other .bat files and server.js always work.
cd /d "%~dp0"

echo ============================================================
echo  The OG Chatbot — startup
echo ============================================================
echo.

:: ── Step 1: Node.js ─────────────────────────────────────────
echo [1/4] Checking / installing Node.js...
call install_node.bat
if %errorlevel% neq 0 (
    echo.
    echo ERROR: Node.js setup failed. Cannot continue.
    pause
    exit /b 1
)
echo.

:: ── Step 2: Ollama ──────────────────────────────────────────
echo [2/4] Checking / installing Ollama...
call install_ollama.bat
if %errorlevel% neq 0 (
    echo.
    echo ERROR: Ollama setup failed. Cannot continue.
    pause
    exit /b 1
)
echo.

:: ── Step 3: Ensure Ollama server is running ─────────────────
echo [3/4] Ensuring Ollama server is running...

:: Quick connectivity check: attempt TCP connect to 127.0.0.1:11434.
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "try { $t = New-Object System.Net.Sockets.TcpClient; $t.Connect('127.0.0.1',11434); $t.Close(); exit 0 } catch { exit 1 }" >nul 2>&1

if %errorlevel% == 0 (
    echo [Ollama] Server already running on 127.0.0.1:11434.
) else (
    echo [Ollama] Starting Ollama server in background...
    start /min "Ollama Server" ollama serve

    :: Wait up to 15 seconds for Ollama to become ready.
    set OLLAMA_READY=0
    for /l %%i in (1,1,15) do (
        if !OLLAMA_READY! == 0 (
            powershell -NoProfile -ExecutionPolicy Bypass -Command ^
              "try { $t = New-Object System.Net.Sockets.TcpClient; $t.Connect('127.0.0.1',11434); $t.Close(); exit 0 } catch { exit 1 }" >nul 2>&1
            if !errorlevel! == 0 (
                set OLLAMA_READY=1
                echo [Ollama] Server ready.
            ) else (
                timeout /t 1 /nobreak >nul
            )
        )
    )

    if !OLLAMA_READY! == 0 (
        echo [Ollama] WARNING: Could not confirm Ollama is ready after 15 s.
        echo          The server may still be starting — proceeding anyway.
    )
)
echo.

:: ── Step 4: Start Node server and open browser ──────────────
echo [4/4] Starting The OG Chatbot server...

:: Verify server.js is present.
if not exist "%~dp0server.js" (
    echo ERROR: server.js not found in %~dp0
    pause
    exit /b 1
)

:: Open the browser after a short delay to give Node time to bind.
start "" /b cmd /c "timeout /t 2 /nobreak >nul && start http://127.0.0.1:3000"

echo.
echo ============================================================
echo  The OG Chatbot is running at http://127.0.0.1:3000
echo  Press Ctrl+C (or close this window) to stop the server.
echo ============================================================
echo.

node "%~dp0server.js"

:: If node exits, pause so the user can read any error output.
echo.
echo Server stopped.
pause
exit /b 0
