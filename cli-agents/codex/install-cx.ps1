#Requires -Version 5.1
<#
.SYNOPSIS
    以 npm 安裝或更新 Codex CLI，並部署 pets。
.DESCRIPTION
    檢查 Node.js/npm；只在兩者皆缺少時用 winget 安裝 Node.js LTS。
    既有 Node.js/npm 由原安裝方式管理，不自動升級。
    安裝時強制遵守套件 engines 並包含 optional dependencies。
    確認實際指令來源與版本後，才複製 pets；覆蓋同名檔案，不刪除額外檔案。
.EXAMPLE
    powershell -ExecutionPolicy Bypass -File .\cli-agents\codex\install-cx.ps1
#>

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '..\install-cli-common.ps1')

# 確認來源與 runtime，安裝成功且指令可用後才部署使用者素材。
function Install-CodexCli {
    $petsSource = Join-Path $PSScriptRoot 'pets'
    if (-not (Test-Path -LiteralPath $petsSource -PathType Container)) { throw "找不到 pets 來源：$petsSource" }

    Write-Host '=== Step 1: Node.js/npm ===' -ForegroundColor Cyan
    Initialize-CliNode -RequireNpm
    $npmCommand = Get-Command npm.cmd -CommandType Application -ErrorAction Stop | Select-Object -First 1
    $npmPrefix = (@(Invoke-CliNative $npmCommand.Source @('prefix', '-g')) -join '').Trim()
    if (-not $npmPrefix) { throw 'npm prefix -g 沒有回傳安裝位置。' }

    Write-Host '=== Step 2: Codex CLI ===' -ForegroundColor Cyan
    Invoke-CliNative $npmCommand.Source @('install', '-g', '--engine-strict', '--include=optional', '@openai/codex') | Out-Host
    $codexExecutable = Join-Path $npmPrefix 'codex.cmd'
    if (-not (Test-Path -LiteralPath $codexExecutable -PathType Leaf)) { throw "找不到 npm 指令：$codexExecutable" }
    Assert-CliVersion $codexExecutable 'Codex CLI'
    Register-CliUserPath $npmPrefix
    Assert-CliCommandSource 'codex' $npmPrefix

    Write-Host '=== Step 3: pets ===' -ForegroundColor Cyan
    $petsDestination = Join-Path $env:USERPROFILE '.codex\pets'
    New-Item -ItemType Directory -Path $petsDestination -Force | Out-Null
    Copy-Item -Path (Join-Path $petsSource '*') -Destination $petsDestination -Recurse -Force
    Write-Host "[OK] Codex CLI 安裝完成，pets 已複製至 $petsDestination" -ForegroundColor Green
}

if ($MyInvocation.InvocationName -ne '.') {
    try { Install-CodexCli } catch {
        Write-Host "[X] ERROR: $_" -ForegroundColor Red
        exit 1
    }
}
