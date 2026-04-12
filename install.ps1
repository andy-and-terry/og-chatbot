<#
.SYNOPSIS
    Windows installer for The OG Chatbot local chat app.

.DESCRIPTION
    - Checks prerequisites (Node.js, npm, Ollama).
    - Runs `npm install`.
    - Pulls the chosen Ollama model (default: qwen2.5:3b).
    - Persists OLLAMA_MODEL as a system environment variable (machine-level).
    - Optionally creates a Desktop shortcut.
    - Optionally starts the app and opens it in the browser.

.PARAMETER Model
    Ollama model to pull and use. Overrides the OLLAMA_MODEL environment variable.
    Defaults to qwen2.5:3b if neither this parameter nor the env var is set.

.EXAMPLE
    .\install.ps1
    .\install.ps1 -Model qwen2.5:7b
#>

[CmdletBinding()]
param(
    [string]$Model = ""
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
function Write-Header {
    param([string]$Text)
    Write-Host ""
    Write-Host "==> $Text" -ForegroundColor Cyan
}

function Write-OK {
    param([string]$Text)
    Write-Host "  [OK] $Text" -ForegroundColor Green
}

function Write-Fail {
    param([string]$Text)
    Write-Host "  [FAIL] $Text" -ForegroundColor Red
}

function Write-Info {
    param([string]$Text)
    Write-Host "  $Text" -ForegroundColor Yellow
}

function Confirm-YesNo {
    param([string]$Prompt, [bool]$Default = $true)
    $hint = if ($Default) { "[Y/n]" } else { "[y/N]" }
    $answer = Read-Host "$Prompt $hint"
    if ([string]::IsNullOrWhiteSpace($answer)) { return $Default }
    return $answer -match '^[Yy]'
}

# ---------------------------------------------------------------------------
# 1. Platform check
# ---------------------------------------------------------------------------
Write-Header "Checking platform"
# $env:OS is 'Windows_NT' on all modern Windows versions and is available in
# both Windows PowerShell 5.x and PowerShell 7+.
if ($env:OS -ne "Windows_NT") {
    Write-Fail "This installer is for Windows only."
    Write-Info "On Linux/macOS, run: npm install && ollama pull qwen2.5:3b && npm start"
    exit 1
}
Write-OK "Running on Windows."

# ---------------------------------------------------------------------------
# 2. Prerequisite checks
# ---------------------------------------------------------------------------
Write-Header "Checking prerequisites"

$missingPrereqs = $false

# --- Node.js ---
if (-not (Get-Command "node" -ErrorAction SilentlyContinue)) {
    Write-Fail "Node.js is not installed or not on PATH."
    Write-Info "Install Node.js LTS from: https://nodejs.org/en/download"
    Write-Info "After installing, restart your terminal and re-run this script."
    $missingPrereqs = $true
} else {
    $nodeVersion = & node --version 2>&1
    Write-OK "Node.js found: $nodeVersion"
}

# --- npm ---
if (-not (Get-Command "npm" -ErrorAction SilentlyContinue)) {
    Write-Fail "npm is not installed or not on PATH."
    Write-Info "npm is bundled with Node.js. Reinstall Node.js from: https://nodejs.org/en/download"
    $missingPrereqs = $true
} else {
    $npmVersion = & npm --version 2>&1
    Write-OK "npm found: v$npmVersion"
}

# --- Ollama ---
if (-not (Get-Command "ollama" -ErrorAction SilentlyContinue)) {
    Write-Fail "Ollama is not installed or not on PATH."
    Write-Info "Download and install Ollama from: https://ollama.com/download/windows"
    Write-Info "After installing, restart your terminal and re-run this script."
    $missingPrereqs = $true
} else {
    $ollamaVersion = & ollama --version 2>&1
    Write-OK "Ollama found: $ollamaVersion"
}

if ($missingPrereqs) {
    Write-Host ""
    Write-Fail "One or more prerequisites are missing. Please install them and re-run install.bat (or install.ps1)."
    exit 2
}

# ---------------------------------------------------------------------------
# 3. Resolve model name
# ---------------------------------------------------------------------------
Write-Header "Choosing Ollama model"

$defaultModel = "qwen2.5:3b"

if ($Model -ne "") {
    $chosenModel = $Model
    Write-OK "Model supplied via -Model parameter: $chosenModel"
} elseif (-not [string]::IsNullOrEmpty($env:OLLAMA_MODEL)) {
    $chosenModel = $env:OLLAMA_MODEL
    Write-OK "Model from OLLAMA_MODEL environment variable: $chosenModel"
} else {
    Write-Info "No model specified. Default is '$defaultModel' (recommended for 8 GB RAM)."
    $userInput = Read-Host "  Press Enter to accept, or type a different model name (e.g. qwen2.5:7b)"
    if ([string]::IsNullOrWhiteSpace($userInput)) {
        $chosenModel = $defaultModel
    } else {
        $chosenModel = $userInput.Trim()
    }
    Write-OK "Using model: $chosenModel"
}

# ---------------------------------------------------------------------------
# 4. npm install
# ---------------------------------------------------------------------------
Write-Header "Installing Node.js dependencies (npm install)"

$repoRoot = $PSScriptRoot
if ([string]::IsNullOrEmpty($repoRoot)) {
    $repoRoot = (Get-Location).Path
}

if (-not (Test-Path (Join-Path $repoRoot "package.json"))) {
    Write-Info "Warning: package.json not found in '$repoRoot'."
    Write-Info "Skipping npm install. If this is unexpected, make sure you are running the script from the repo root."
} else {
    Push-Location $repoRoot
    try {
        & npm install
        if ($LASTEXITCODE -ne 0) {
            Write-Fail "npm install failed (exit code $LASTEXITCODE)."
            exit $LASTEXITCODE
        }
        Write-OK "npm install completed."
    } finally {
        Pop-Location
    }
}

# ---------------------------------------------------------------------------
# 5. Pull Ollama model
# ---------------------------------------------------------------------------
Write-Header "Pulling Ollama model: $chosenModel"
Write-Info "This may take a while on the first run (download size varies by model)."

& ollama pull $chosenModel
if ($LASTEXITCODE -ne 0) {
    Write-Fail "ollama pull failed (exit code $LASTEXITCODE)."
    exit $LASTEXITCODE
}
Write-OK "Model '$chosenModel' is ready."

# ---------------------------------------------------------------------------
# 6. Persist OLLAMA_MODEL (session + machine/user level)
# ---------------------------------------------------------------------------
Write-Header "Setting OLLAMA_MODEL"

$env:OLLAMA_MODEL = $chosenModel
Write-OK "OLLAMA_MODEL set to '$chosenModel' for this session."

try {
    [Environment]::SetEnvironmentVariable('OLLAMA_MODEL', $chosenModel, 'Machine')
    Write-OK "OLLAMA_MODEL persisted at Machine (system) level."
} catch {
    # Fall back to user-level if not running as admin.
    try {
        [Environment]::SetEnvironmentVariable('OLLAMA_MODEL', $chosenModel, 'User')
        Write-OK "OLLAMA_MODEL persisted at User level (run as Administrator to persist system-wide)."
    } catch {
        Write-Info "Could not persist OLLAMA_MODEL automatically. Set it manually if needed:"
        Write-Info "  [Environment]::SetEnvironmentVariable('OLLAMA_MODEL', '$chosenModel', 'User')"
    }
}

# ---------------------------------------------------------------------------
# 7. Optional Desktop shortcut
# ---------------------------------------------------------------------------
Write-Host ""
$createShortcut = Confirm-YesNo "Create Desktop shortcut for The OG Chatbot?" $true
if ($createShortcut) {
    try {
        $desktopPath = [Environment]::GetFolderPath("Desktop")
        $shortcutPath = Join-Path $desktopPath "The OG Chatbot.lnk"
        $wsh = New-Object -ComObject WScript.Shell
        $shortcut = $wsh.CreateShortcut($shortcutPath)
        $shortcut.TargetPath = Join-Path $repoRoot "start.bat"
        $shortcut.WorkingDirectory = $repoRoot
        $shortcut.Description = "Launch The OG Chatbot"
        $shortcut.Save()
        Write-OK "Desktop shortcut created: $shortcutPath"
    } catch {
        Write-Info "Could not create Desktop shortcut: $_"
    }
}

# ---------------------------------------------------------------------------
# 8. Optionally start the app
# ---------------------------------------------------------------------------
Write-Host ""
Write-Header "Installation complete"
Write-OK "The OG Chatbot is ready to use."
Write-Host ""

$startNow = Confirm-YesNo "Would you like to start the app now?" $true
if ($startNow) {
    Write-Header "Starting the app"
    # Open browser after a short delay to let the server bind.
    Start-Job -ScriptBlock { Start-Sleep -Seconds 2; Start-Process "http://localhost:3000" } | Out-Null
    Push-Location $repoRoot
    try {
        & npm start
        if ($LASTEXITCODE -ne 0) {
            Write-Fail "npm start failed (exit code $LASTEXITCODE)."
            exit $LASTEXITCODE
        }
    } finally {
        Pop-Location
    }
}

Write-Host ""
Write-Info "To run without the desktop shortcut run one of these commands:"
Write-Info "  CMD:        cd /d `"$repoRoot`" && start.bat"
Write-Info "  PowerShell: Set-Location `"$repoRoot`"; .\start.bat"
Write-Host ""

exit 0
