#Requires -Version 5.1

[CmdletBinding()]
param(
    [string]$CustomPromptPath
)

$ErrorActionPreference = 'Stop'

$sourceRoot = $PSScriptRoot
$homeRoot = $env:USERPROFILE
$customSource = Join-Path $sourceRoot 'prompt-custom.md'
if ($PSBoundParameters.ContainsKey('CustomPromptPath')) {
    if ([string]::IsNullOrWhiteSpace($CustomPromptPath)) {
        throw 'CustomPromptPath must name a file.'
    }
    $absolute = $CustomPromptPath -match '^(?:[A-Za-z]:[\\/]|[\\/]{2}[^\\/]+[\\/][^\\/]+(?:[\\/]|$))'
    if (-not $absolute -and ($CustomPromptPath -match '^[A-Za-z]:' -or [IO.Path]::IsPathRooted($CustomPromptPath))) {
        throw 'Drive-relative and root-relative paths are not supported.'
    }
    if ($absolute) {
        $customSource = [IO.Path]::GetFullPath($CustomPromptPath)
    } else {
        $customSource = [IO.Path]::GetFullPath((Join-Path $sourceRoot $CustomPromptPath))
    }
}
$promptSources = @(
    (Join-Path $sourceRoot 'prompt-user.md')
    $customSource
)
$installItems = @(
    [PSCustomObject]@{
        Template = Join-Path $sourceRoot 'claude-code\.claude\CLAUDE.md'
        Target   = Join-Path $homeRoot '.claude\CLAUDE.md'
    }
    [PSCustomObject]@{
        Template = Join-Path $sourceRoot 'codex\.codex\AGENTS.md'
        Target   = Join-Path $homeRoot '.codex\AGENTS.md'
    }
    [PSCustomObject]@{
        Template = Join-Path $sourceRoot 'github-copilot\.copilot\copilot-instructions.md'
        Target   = Join-Path $homeRoot '.copilot\copilot-instructions.md'
    }
)

foreach ($path in $promptSources + @($installItems | ForEach-Object { $_.Template })) {
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        throw "Source file not found: $path"
    }
}

$prompts = @($promptSources | ForEach-Object {
    [PSCustomObject]@{
        Name    = Split-Path -Leaf $_
        Content = Get-Content -LiteralPath $_ -Raw -Encoding UTF8
    }
})
$backupSuffix = Get-Date -Format 'yyMMddHHmmss'

Write-Host '=== Install common prompts ===' -ForegroundColor Cyan

foreach ($item in $installItems) {
    $targetDirectory = Split-Path -Parent $item.Target
    New-Item -ItemType Directory -Path $targetDirectory -Force | Out-Null
    if (Test-Path -LiteralPath $item.Target -PathType Leaf) {
        $backupPath = "$($item.Target)_$backupSuffix"
        Move-Item -LiteralPath $item.Target -Destination $backupPath -Force
        Write-Host "  [Backup] $($item.Target) -> $backupPath" -ForegroundColor Yellow
    }
    Copy-Item -LiteralPath $item.Template -Destination $item.Target -Force
    Write-Host "  [OK] Template: $($item.Target)" -ForegroundColor Green
}

foreach ($item in $installItems) {
    foreach ($prompt in $prompts) {
        Add-Content -LiteralPath $item.Target -Value ("`r`n`r`n" + $prompt.Content) -Encoding UTF8 -NoNewline
        Write-Host "  [OK] $($prompt.Name): $($item.Target)" -ForegroundColor Green
    }
}

Write-Host 'Done.' -ForegroundColor Green
