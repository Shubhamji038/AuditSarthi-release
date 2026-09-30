#Requires -Version 5.1
<#
  Audit Sarthi — one-line installer (Windows 10/11).

  Run this in PowerShell:
    irm https://raw.githubusercontent.com/Shubhamji038/AuditSarthi-release/main/install.ps1 | iex

  What it does:
    1. Downloads the Audit Sarthi setup exe from GitHub Releases
    2. Installs it silently (Python backend is bundled inside - nothing else to install)
    3. Only if the bundled backend is missing: finds Python 3.10+
       (auto-installs 3.13 via winget) + backend packages
    4. Launches the app
#>
$ErrorActionPreference = 'Stop'

$Version = '0.2.1'
$Repo    = 'Shubhamji038/AuditSarthi-release'
$Asset   = 'Audit.Sarthi.Setup.0.2.1.exe'
$Url     = "https://github.com/$Repo/releases/download/v$Version/$Asset"
$AppDir  = Join-Path $env:LOCALAPPDATA 'Programs\Audit Sarthi'

Write-Host '== Audit Sarthi installer ==' -ForegroundColor Green

function Test-PyExe($exe) {
    try {
        $out = & $exe --version 2>&1
        if ($LASTEXITCODE -eq 0 -and "$out" -match 'Python 3\.(\d+)') {
            return ([int]$Matches[1] -ge 10)
        }
    } catch { }
    return $false
}

function Find-Python {
    # Well-known install folders first (beats the Microsoft Store stub),
    # then whatever is on PATH. Only version-validated exes are returned.
    $cands = @(
        (Join-Path $env:LOCALAPPDATA 'Programs\Python\Python313\python.exe'),
        (Join-Path $env:LOCALAPPDATA 'Programs\Python\Python312\python.exe'),
        'C:\Python313\python.exe',
        'C:\Python312\python.exe',
        'C:\Program Files\Python313\python.exe',
        'C:\Program Files\Python312\python.exe'
    )
    foreach ($c in @('python', 'py')) {
        $cmd = Get-Command $c -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($cmd) { $cands += $cmd.Source }
    }
    $seen = @{}
    foreach ($p in $cands) {
        if (-not $p -or $seen.ContainsKey($p)) { continue }
        $seen[$p] = $true
        if ((Test-Path -LiteralPath $p) -and (Test-PyExe $p)) { return $p }
    }
    return $null
}

function Install-Python {
    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) { return $null }
    Write-Host 'Python not found - installing Python 3.13 silently via winget (takes a minute)...'
    winget install -e --id Python.Python.3.13 --silent `
        --accept-source-agreements --accept-package-agreements | Out-Null
    if ($LASTEXITCODE -ne 0) { return $null }
    $env:Path = [Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' +
                [Environment]::GetEnvironmentVariable('Path', 'User')
    return (Find-Python)
}

function Ensure-PythonFallback {
    # Only used when the app ships WITHOUT its bundled backend.
    $pyExe = Find-Python
    if (-not $pyExe) { $pyExe = Install-Python }
    if ($pyExe) {
        Write-Host "Python ready: $pyExe"
        Write-Host 'Installing backend packages (openpyxl requests pywin32 pypdf)...'
        & $pyExe -m pip install --upgrade openpyxl requests pywin32 pypdf
    } else {
        Write-Warning 'Python 3.10+ is missing and could not be installed automatically. Install it from https://www.python.org/downloads/ (tick Add Python to PATH), then re-run extraction.'
    }
}

# 1. Download the setup exe
$dest = Join-Path $env:TEMP $Asset
Write-Host "Downloading $Asset ..."
Invoke-WebRequest -Uri $Url -OutFile $dest -UseBasicParsing

# 2. Silent install (NSIS one-click, per-user - no admin needed)
Write-Host 'Installing Audit Sarthi (silent)...'
Start-Process -FilePath $dest -Wait -ArgumentList '/S'

# 3. Bundled backend? If yes, no Python needed at all.
$bundled = Join-Path $AppDir 'resources\python\tally_backend.exe'
if (Test-Path -LiteralPath $bundled) {
    Write-Host 'Bundled backend found - no Python setup needed.'
} else {
    Write-Host 'No bundled backend - falling back to system Python...'
    Ensure-PythonFallback
}

# 4. Launch
$app = Join-Path $AppDir 'Audit Sarthi.exe'
if (Test-Path -LiteralPath $app) {
    Write-Host 'Launching Audit Sarthi...' -ForegroundColor Green
    Start-Process $app
} else {
    Write-Warning 'Installed but app exe was not found - check the installer output above.'
}

Write-Host ''
Write-Host 'Next steps: open Tally (company OPEN, XML/HTTP on port 9000), then in Audit Sarthi: Test connection -> Refresh companies -> Extract.'
