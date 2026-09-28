#Requires -Version 5.1
<#
  Audit Sarthi — one-line installer (Windows 10/11).

  Run this in PowerShell:
    irm https://raw.githubusercontent.com/Shubhamji038/AuditSarthi-release/main/install.ps1 | iex

  What it does:
    1. Checks Python (warns with download link if missing)
    2. Installs backend packages (openpyxl, requests, pywin32)
    3. Downloads the Audit Sarthi setup exe from GitHub Releases
    4. Installs it silently and launches the app
#>
$ErrorActionPreference = 'Stop'

$Version = '0.1.0'
$Repo    = 'Shubhamji038/AuditSarthi-release'
$Asset   = 'Audit.Sarthi.Setup.0.1.0.exe'
$Url     = "https://github.com/$Repo/releases/download/v$Version/$Asset"

Write-Host '== Audit Sarthi installer ==' -ForegroundColor Green

# 1. Python check + backend packages
$py = Get-Command python, py -ErrorAction SilentlyContinue | Select-Object -First 1
if (-not $py) {
    Write-Warning 'Python 3.10+ not found. Install it from https://www.python.org/downloads/ (tick "Add Python to PATH"), then re-run this script.'
} else {
    Write-Host "Python found: $($py.Source)"
    Write-Host 'Installing backend packages (openpyxl requests pywin32)...'
    & $py.Source -m pip install --upgrade openpyxl requests pywin32
}

# 2. Download the setup exe
$dest = Join-Path $env:TEMP $Asset
Write-Host "Downloading $Asset ..."
Invoke-WebRequest -Uri $Url -OutFile $dest -UseBasicParsing

# 3. Silent install (NSIS one-click, per-user — no admin needed)
Write-Host 'Installing Audit Sarthi (silent)...'
Start-Process -FilePath $dest -Wait -ArgumentList '/S'

# 4. Launch
$app = Join-Path $env:LOCALAPPDATA 'Programs\Audit Sarthi\Audit Sarthi.exe'
if (Test-Path -LiteralPath $app) {
    Write-Host 'Launching Audit Sarthi...' -ForegroundColor Green
    Start-Process $app
} else {
    Write-Warning "Installed but app exe not found at $app — check the installer output above."
}

Write-Host ''
Write-Host 'Next steps: open Tally (company OPEN, XML/HTTP on port 9000), then in Audit Sarthi: Test connection -> Refresh companies -> Extract.'
