<#
.SYNOPSIS
    Windows installer for the offlineAI local chat app.

.DESCRIPTION
    - Checks prerequisites (Node.js, npm, Ollama).
    - Runs `npm install`.
    - Pulls the chosen Ollama model (default: qwen2.5:3b).
    - Sets OLLAMA_MODEL for the current session and shows how to persist it.
    - Optionally starts the app.

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
# 6. Set OLLAMA_MODEL for this session + persistence instructions
# ---------------------------------------------------------------------------
Write-Header "Setting OLLAMA_MODEL"

$env:OLLAMA_MODEL = $chosenModel
Write-OK "OLLAMA_MODEL set to '$chosenModel' for this PowerShell session."

Write-Host ""
Write-Info "To persist this across sessions, run ONE of the following:"
Write-Info ""
Write-Info "  (User) [Environment]::SetEnvironmentVariable('OLLAMA_MODEL', '$chosenModel', 'User')"
Write-Info "  (System, admin) [Environment]::SetEnvironmentVariable('OLLAMA_MODEL', '$chosenModel', 'Machine')"
Write-Info ""
Write-Info "Or add the following line to your PowerShell profile (`$PROFILE):"
Write-Info "  `$env:OLLAMA_MODEL = '$chosenModel'"

# ---------------------------------------------------------------------------
# 7. Optionally start the app
# ---------------------------------------------------------------------------
Write-Host ""
Write-Header "Installation complete"
Write-OK "offlineAI is ready to use."
Write-Host ""

$startNow = Confirm-YesNo "Would you like to start the app now?" $true
if ($startNow) {
    Write-Header "Starting the app (npm start)"
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
} else {
    Write-Host ""
    Write-Info "To start the app later, run from the repo directory:"
    Write-Info "  npm start"
    Write-Info "Or double-click install.bat and choose 'start' when prompted."
}

exit 0
