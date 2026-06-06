param(
    [string]$AppRoot = "",
    [int]$Port = 7000,
    [switch]$NoBrowser
)

$ErrorActionPreference = "Stop"

if (-not $AppRoot) {
    $AppRoot = Split-Path -Parent $PSScriptRoot
}

$LoginUrl = "http://127.0.0.1:$Port/login"
$PythonExe = Join-Path $AppRoot "venv\Scripts\python.exe"
$LogDir = Join-Path $AppRoot "logs"

function Show-LauncherError {
    param([string]$Message)

    try {
        Add-Type -AssemblyName System.Windows.Forms -ErrorAction Stop
        [System.Windows.Forms.MessageBox]::Show($Message, "Odysseus Launcher", "OK", "Error") | Out-Null
    } catch {
        Write-Error $Message
    }
}

function Normalize-PathEnvironment {
    $pathValue = [Environment]::GetEnvironmentVariable("Path", "Process")
    $upperValue = [Environment]::GetEnvironmentVariable("PATH", "Process")

    if ($pathValue -and $upperValue -and $pathValue -eq $upperValue) {
        [Environment]::SetEnvironmentVariable("PATH", $null, "Process")
        [Environment]::SetEnvironmentVariable("Path", $pathValue, "Process")
    }
}

function Test-OdysseusReady {
    try {
        $response = Invoke-WebRequest -Uri $LoginUrl -UseBasicParsing -TimeoutSec 2
        return ([int]$response.StatusCode -eq 200)
    } catch {
        return $false
    }
}

function Get-ChromePath {
    $candidates = @(
        "$env:ProgramFiles\Google\Chrome\Application\chrome.exe",
        "${env:ProgramFiles(x86)}\Google\Chrome\Application\chrome.exe",
        "$env:LocalAppData\Google\Chrome\Application\chrome.exe"
    )

    foreach ($candidate in $candidates) {
        if ($candidate -and (Test-Path -LiteralPath $candidate)) {
            return $candidate
        }
    }

    $chrome = Get-Command "chrome.exe" -ErrorAction SilentlyContinue
    if ($chrome) {
        return $chrome.Source
    }

    return $null
}

try {
    Normalize-PathEnvironment

    if (-not (Test-Path -LiteralPath $AppRoot)) {
        throw "Could not find Odysseus app folder: $AppRoot"
    }

    if (-not (Test-Path -LiteralPath (Join-Path $AppRoot "app.py"))) {
        throw "Could not find app.py in: $AppRoot"
    }

    if (-not (Test-Path -LiteralPath $PythonExe)) {
        throw "Could not find Odysseus virtualenv Python at: $PythonExe"
    }

    New-Item -ItemType Directory -Force -Path $LogDir | Out-Null

    if (-not (Test-OdysseusReady)) {
        $stamp = Get-Date -Format "yyyyMMdd-HHmmss"
        $outLog = Join-Path $LogDir "shortcut-uvicorn-$stamp.out.log"
        $errLog = Join-Path $LogDir "shortcut-uvicorn-$stamp.err.log"
        $uvicornArgs = @("-m", "uvicorn", "app:app", "--host", "127.0.0.1", "--port", [string]$Port)

        Start-Process `
            -FilePath $PythonExe `
            -ArgumentList $uvicornArgs `
            -WorkingDirectory $AppRoot `
            -WindowStyle Hidden `
            -RedirectStandardOutput $outLog `
            -RedirectStandardError $errLog | Out-Null

        $ready = $false
        for ($i = 0; $i -lt 90; $i++) {
            Start-Sleep -Seconds 1
            if (Test-OdysseusReady) {
                $ready = $true
                break
            }
        }

        if (-not $ready) {
            throw "Odysseus did not become ready at $LoginUrl within 90 seconds. Check logs in: $LogDir"
        }
    }

    if (-not $NoBrowser) {
        $chromePath = Get-ChromePath
        if ($chromePath) {
            Start-Process -FilePath $chromePath -ArgumentList $LoginUrl | Out-Null
        } else {
            Start-Process $LoginUrl | Out-Null
        }
    }
} catch {
    Show-LauncherError $_.Exception.Message
    exit 1
}
