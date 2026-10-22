# Shared helpers for the PowerShell scripts in this folder. Dot-source it:
#
#   . "$PSScriptRoot\_common.ps1"
#
# It gives every script the same console output:
#
#   [luma] ==> Running tests              step (cyan)
#   [luma]     Working dir: ...           detail (gray)
#   [luma] OK  Finished in 1m 15s         success (green)
#   [luma] ERR Failed after 3s: ...       error (red)

$ErrorActionPreference = "Stop"

$script:LogTag = "[luma]"
$script:AppDir = Split-Path -Parent $PSScriptRoot
$script:EnvFileName = ".env"

function Write-Step([string]$Message) {
    Write-Host "$script:LogTag ==> $Message" -ForegroundColor Cyan
}

function Write-Info([string]$Message) {
    Write-Host "$script:LogTag     $Message" -ForegroundColor DarkGray
}

function Write-Ok([string]$Message) {
    Write-Host "$script:LogTag OK  $Message" -ForegroundColor Green
}

function Write-Fail([string]$Message) {
    Write-Host "$script:LogTag ERR $Message" -ForegroundColor Red
}

function Format-Elapsed([TimeSpan]$Span) {
    $seconds = [int][math]::Round($Span.TotalSeconds)
    if ($seconds -ge 60) {
        return "{0}m {1}s" -f [math]::Floor($seconds / 60), ($seconds % 60)
    }
    return "${seconds}s"
}

# Runs $Body as one task: logs its title, and at the end how long it took.
# Any error thrown inside is logged and ends the script with exit code 1.
function Start-Task([string]$Title, [scriptblock]$Body) {
    $startedAt = Get-Date
    Write-Step $Title
    try {
        & $Body
    }
    catch {
        Write-Fail ("Failed after {0}: {1}" -f (Format-Elapsed ((Get-Date) - $startedAt)), $_.Exception.Message)
        exit 1
    }
    Write-Ok ("Finished in {0}" -f (Format-Elapsed ((Get-Date) - $startedAt)))
}

# Moves to app/ so the scripts work from any folder.
function Enter-AppDir {
    Set-Location $script:AppDir
    Write-Info "Working dir: $script:AppDir"
}

function Assert-EnvFile {
    if (-not (Test-Path $script:EnvFileName)) {
        throw "Missing env file app\$script:EnvFileName. Copy app\.env.example to app\$script:EnvFileName and fill in the values."
    }
    Write-Info "Env file: $script:EnvFileName"
}

# Runs flutter with the given arguments, logging the exact command first.
function Invoke-Flutter {
    if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
        throw "Flutter was not found in PATH. Install it (https://docs.flutter.dev/get-started/install) and reopen the terminal."
    }
    Write-Info ("Command: flutter $($args -join ' ')").TrimEnd()
    & flutter @args
    if ($LASTEXITCODE -ne 0) {
        throw "flutter $($args[0]) failed (exit code $LASTEXITCODE)"
    }
}
