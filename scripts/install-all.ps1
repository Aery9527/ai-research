#Requires -Version 5.1
<#
.SYNOPSIS
    Menu-driven installer for Claude Code CLI, Codex CLI, the PowerShell profile, and the
    desktop-app hotkey scripts.

.DESCRIPTION
    Presents a menu and runs whichever of the following the user selects
    (comma-separated, e.g. "1,3"); leaving the input blank or entering 0 runs all six,
    always in the fixed order 1 -> 2 -> 3 -> 4 -> 5 -> 6 regardless of the order typed:
      1) Claude Code CLI + status line -> cli-agents\claude-code\install-cc.ps1
      2) Codex CLI + pet sprites        -> cli-agents\codex\install-cx.ps1
      3) PowerShell profile             -> tool\pwsh\install.ps1
      4) Shared system prompt           -> cli-agents\install-sys-prompt.ps1
      5) Claude Desktop hotkey          -> scripts\setup-cc-desktop-ahk.ps1
      6) ChatGPT Desktop hotkey         -> scripts\setup-cx-desktop-ahk.ps1

    Each sub-script fails fast on its own ($ErrorActionPreference = 'Stop' plus explicit
    exit codes); a failure in one selected item stops the remaining items.

.EXAMPLE
    powershell -ExecutionPolicy Bypass -File .\scripts\install-all.ps1
#>

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path

$items = [ordered]@{
    '1' = [PSCustomObject]@{ Label = 'Claude Code CLI (install-cc)';   Path = Join-Path $repoRoot 'cli-agents\claude-code\install-cc.ps1' }
    '2' = [PSCustomObject]@{ Label = 'Codex CLI (install-cx)';        Path = Join-Path $repoRoot 'cli-agents\codex\install-cx.ps1' }
    '3' = [PSCustomObject]@{ Label = 'PowerShell 腳本 (install.ps1)'; Path = Join-Path $repoRoot 'tool\pwsh\install.ps1' }
    '4' = [PSCustomObject]@{ Label = '系統提示詞 (install-sys-prompt)'; Path = Join-Path $repoRoot 'cli-agents\install-sys-prompt.ps1' }
    '5' = [PSCustomObject]@{ Label = 'Claude Desktop 熱鍵 (setup-cc-desktop-ahk)'; Path = Join-Path $repoRoot 'scripts\setup-cc-desktop-ahk.ps1' }
    '6' = [PSCustomObject]@{ Label = 'ChatGPT Desktop 熱鍵 (setup-cx-desktop-ahk)'; Path = Join-Path $repoRoot 'scripts\setup-cx-desktop-ahk.ps1' }
}

Write-Host '==========================================' -ForegroundColor Cyan
Write-Host '   Install All' -ForegroundColor Cyan
Write-Host '==========================================' -ForegroundColor Cyan
Write-Host ''
foreach ($key in $items.Keys) {
    Write-Host "  [$key] $($items[$key].Label)" -ForegroundColor Green
}
Write-Host ''
Write-Host '  [0] 全部安裝（預設）' -ForegroundColor Yellow
Write-Host ''
Write-Host '==========================================' -ForegroundColor Cyan

$raw = Read-Host '請輸入要安裝的項目編號，可用逗號分隔多選（例如 1,3；留空或輸入 0 = 全部安裝）'

$selectedKeys = $items.Keys
if (-not [string]::IsNullOrWhiteSpace($raw) -and $raw.Trim() -ne '0') {
    $requested = $raw -split ',' | ForEach-Object { $_.Trim() }
    $invalid = $requested | Where-Object { -not $items.Contains($_) }
    if ($invalid) {
        $invalidDisplay = $invalid | ForEach-Object { if ($_ -eq '') { '(空白)' } else { $_ } }
        Write-Host "  [X] ERROR: 無效的選項: $($invalidDisplay -join ', ')" -ForegroundColor Red
        exit 1
    }
    $selectedKeys = $items.Keys | Where-Object { $requested -contains $_ }
}

Write-Host ''
foreach ($key in $selectedKeys) {
    $item = $items[$key]
    if (-not (Test-Path -LiteralPath $item.Path -PathType Leaf)) {
        Write-Host "  [X] ERROR: 找不到腳本: $($item.Path)" -ForegroundColor Red
        exit 1
    }
    Write-Host "=== [$key] $($item.Label) ===" -ForegroundColor Cyan
    $global:LASTEXITCODE = 0
    & $item.Path
    if ($LASTEXITCODE -ne 0) {
        Write-Host "  [X] ERROR: [$key] $($item.Label) 失敗 (exit $LASTEXITCODE)" -ForegroundColor Red
        exit 1
    }
    Write-Host ''
}

Write-Host '[OK] 全部完成' -ForegroundColor Green
