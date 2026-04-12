@echo off
setlocal EnableExtensions EnableDelayedExpansion

set "REPO_DIR=%~dp0"
set "REPO_DIR=%REPO_DIR:~0,-1%"

echo.
echo ===============================
echo   The OG Chatbot - start.bat
echo ===============================
echo Repo: "%REPO_DIR%"
echo.

REM Refresh PATH for this session (Machine + User)
for /f "tokens=2,*" %%A in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" /v Path 2^>nul ^| find /i "Path"') do set "MACHINE_PATH=%%B"
for /f "tokens=2,*" %%A in ('reg query "HKCU\Environment" /v Path 2^>nul ^| find /i "Path"') do set "USER_PATH=%%B"

if defined MACHINE_PATH (
  if defined USER_PATH (
    set "PATH=!MACHINE_PATH!;!USER_PATH!"
  ) else (
    set "PATH=!MACHINE_PATH!"
  )
)

where node >nul 2>nul
if errorlevel 1 (
  echo [ERROR] Node.js not found on PATH.
  echo Please install Node.js (LTS), then re-run start.bat.
  echo.
  echo To run without the desktop shortcut run one of these commands:
  echo   CMD: cd /d "%REPO_DIR%" ^&^& start.bat
  echo   PowerShell: Set-Location "%REPO_DIR%"; .\start.bat
  pause
  exit /b 2
)

where ollama >nul 2>nul
if errorlevel 1 (
  echo [ERROR] Ollama not found on PATH.
  echo Please install Ollama, then re-run start.bat.
  echo.
  echo To run without the desktop shortcut run one of these commands:
  echo   CMD: cd /d "%REPO_DIR%" ^&^& start.bat
  echo   PowerShell: Set-Location "%REPO_DIR%"; .\start.bat
  pause
  exit /b 2
)

echo [INFO] Starting Ollama server...
start "" /min cmd /c "ollama serve"

echo [INFO] Starting Node server...
start "" /min cmd /c "cd /d ""%REPO_DIR%"" && node server.js"

echo [INFO] Waiting for http://127.0.0.1:3000 ...
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$u='http://127.0.0.1:3000';" ^
  "$ok=$false;" ^
  "for($i=0;$i -lt 40;$i++){" ^
  "  try { Invoke-WebRequest -UseBasicParsing -TimeoutSec 1 $u | Out-Null; $ok=$true; break } catch { Start-Sleep -Milliseconds 250 }" ^
  "}" ^
  "if($ok){ Start-Process $u } else { Write-Host 'Server not responding yet; open manually: ' $u -ForegroundColor Yellow }"

echo.
set "ANSWER=Y"
set /p "ANSWER=Create Desktop shortcut for The OG Chatbot? (Y/n): "
if /i "!ANSWER!"=="N" goto :PRINT_NOTE

echo [INFO] Creating Desktop shortcut...
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$repo='%REPO_DIR%';" ^
  "$desktop=[Environment]::GetFolderPath('Desktop');" ^
  "$lnk=Join-Path $desktop 'The OG Chatbot.lnk';" ^
  "$w=New-Object -ComObject WScript.Shell;" ^
  "$s=$w.CreateShortcut($lnk);" ^
  "$s.TargetPath='cmd.exe';" ^
  "$s.Arguments='/c """"'+(Join-Path $repo 'start.bat')+'""""';" ^
  "$s.WorkingDirectory=$repo;" ^
  "$s.IconLocation='%SystemRoot%\System32\cmd.exe,0';" ^
  "$s.Save();"

:PRINT_NOTE
echo.
echo To run without the desktop shortcut run one of these commands:
echo   CMD: cd /d "%REPO_DIR%" ^&^& start.bat
echo   PowerShell: Set-Location "%REPO_DIR%"; .\start.bat
echo.

endlocal
exit /b 0
