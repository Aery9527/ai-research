#Requires -Version 5.1
# 建立或移除 .claude/skills 到 .agents/skills 的本機 junction。
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$sourcePath = Join-Path $repoRoot '.agents\skills'
$linkPath = Join-Path $repoRoot '.claude\skills'

Write-Host '=== Agent Skills Linker ===' -ForegroundColor Cyan
Write-Host '  來源：.agents/skills；本機連結：.claude/skills' -ForegroundColor Blue
Write-Host '  [0] 取消' -ForegroundColor Yellow
Write-Host '  [1] 建立或修復整個 skills 目錄的 junction' -ForegroundColor Green
Write-Host '  [3] 移除指向此專案 skills 的 junction' -ForegroundColor Green
$choice = Read-Host '請輸入選項 (0, 1, 3)'

if ($choice -eq '0') {
    Write-Host '  [!] 已取消' -ForegroundColor Yellow
    exit 0
}
if ($choice -notin @('1', '3')) {
    throw '無效選項；請選擇 0、1 或 3。'
}

$linkInfo = Get-Item -Force -LiteralPath $linkPath -ErrorAction SilentlyContinue
if ($null -ne $linkInfo -and $linkInfo.LinkType -notin @('Junction', 'SymbolicLink')) {
    throw '.claude/skills 是實體目錄或檔案；請先保留內容並遷移到 .agents/skills。'
}

if ($choice -eq '1') {
    $sourceInfo = Get-Item -Force -LiteralPath $sourcePath -ErrorAction SilentlyContinue
    if ($null -eq $sourceInfo -or -not $sourceInfo.PSIsContainer -or $sourceInfo.Attributes -band [IO.FileAttributes]::ReparsePoint) {
        throw '.agents/skills 必須是存在的實體目錄；請先完成 skills 遷移。'
    }
    if ($null -ne $linkInfo) {
        # 只移除 link 本身，保留其原有目標的內容。
        [IO.Directory]::Delete($linkPath)
    }
    New-Item -ItemType Directory -Path (Split-Path -Parent $linkPath) -Force | Out-Null
    New-Item -ItemType Junction -Path $linkPath -Target $sourcePath | Out-Null
    Write-Host '  [OK] .claude/skills -> .agents/skills' -ForegroundColor Green
} elseif ($null -eq $linkInfo) {
    Write-Host '  [!] .claude/skills 不存在，無需移除' -ForegroundColor Yellow
} else {
    $targetPath = $linkInfo.Target | Select-Object -First 1
    if (-not [IO.Path]::IsPathRooted($targetPath)) {
        $targetPath = Join-Path (Split-Path -Parent $linkPath) $targetPath
    }
    if ([IO.Path]::GetFullPath($targetPath).TrimEnd('\') -ne $sourcePath.TrimEnd('\')) {
        throw '.claude/skills 指向其他位置，保留此連結。'
    }
    [IO.Directory]::Delete($linkPath)
    Write-Host '  [OK] 已移除 .claude/skills 連結，來源內容保留' -ForegroundColor Green
}

exit 0
