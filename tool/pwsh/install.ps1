$ErrorActionPreference = 'Stop'

$documents = [Environment]::GetFolderPath([Environment+SpecialFolder]::MyDocuments)
$profileDest = Join-Path $documents "PowerShell"
$toolDest = Join-Path $HOME ".config\powershell"

New-Item -ItemType Directory -Path $profileDest -Force | Out-Null
New-Item -ItemType Directory -Path $toolDest -Force | Out-Null

Copy-Item (Join-Path $PSScriptRoot "Microsoft.PowerShell_profile.ps1") $profileDest -Force
Write-Host "[OK] Microsoft.PowerShell_profile.ps1 -> $profileDest" -ForegroundColor Green

Get-ChildItem $PSScriptRoot -File |
    Where-Object { $_.Name -notin @("Microsoft.PowerShell_profile.ps1", "install.ps1") } |
    ForEach-Object {
        Copy-Item $_.FullName $toolDest -Force
        Write-Host "[OK] $($_.Name) -> $toolDest" -ForegroundColor Green
    }
