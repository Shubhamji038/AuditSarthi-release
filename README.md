# AuditSarthi-release

Public download home for **Audit Sarthi** — Tally to audit-ready Excel+PDF desktop app.

## Install in one line (Windows 10/11, PowerShell)

```powershell
irm https://raw.githubusercontent.com/Shubhamji038/AuditSarthi-release/main/install.ps1 | iex
```

This checks Python, installs backend packages (`openpyxl requests pywin32`),
downloads the latest setup exe, installs it silently, and launches the app.

## Manual install

Go to **[Releases](../../releases)** and download the latest
`Audit Sarthi Setup x.y.z.exe` installer, then run it. You still need
Python 3.10+ with `pip install openpyxl requests pywin32`, plus Tally running
with XML/HTTP on port 9000.

> Source code lives in the private `AuditSarthi` repo; this repo hosts downloads only.
