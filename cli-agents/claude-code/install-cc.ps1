#Requires -Version 5.1
<#
.SYNOPSIS
    安裝 Claude Code 官方原生版，並部署 status line 與 hooks。
.DESCRIPTION
    先檢查 Git Bash，並確保 status line 所需的 Node.js 可執行。
    缺 Node.js 時才用 winget 安裝 LTS；既有 Node.js 由原安裝方式管理。
    下載官方 PowerShell 安裝器，以子程序執行並驗證原生版。
    原生版可用後，移除目前 npm prefix 的舊 Claude 套件，再確認指令來源。
.EXAMPLE
    powershell -ExecutionPolicy Bypass -File .\cli-agents\claude-code\install-cc.ps1
#>

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '..\install-cli-common.ps1')

# 與 status line 安裝器使用相同候選位置，排除 WSL launcher 與套件管理器 shim。
function Find-ClaudeGitBash {
    $candidates = [Collections.Generic.List[string]]::new()
    $gitCommand = Get-Command git.exe -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($gitCommand) {
        $gitDirectory = Split-Path -Parent $gitCommand.Source
        $candidates.Add((Join-Path $gitDirectory 'bash.exe'))
        $candidates.Add((Join-Path $gitDirectory '..\bin\bash.exe'))
    }
    $bashCommand = Get-Command bash.exe -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($bashCommand) { $candidates.Add($bashCommand.Source) }
    foreach ($base in @($env:ProgramFiles, ${env:ProgramFiles(x86)}, (Join-Path $env:LOCALAPPDATA 'Programs'))) {
        if ($base) { $candidates.Add((Join-Path $base 'Git\bin\bash.exe')) }
    }
    foreach ($candidate in $candidates) {
        try { $resolved = (Resolve-Path -LiteralPath $candidate -ErrorAction Stop).Path } catch { continue }
        if ($resolved.StartsWith($env:SystemRoot, [StringComparison]::OrdinalIgnoreCase)) { continue }
        if (Test-Path -LiteralPath (Join-Path (Split-Path -Parent $resolved) 'git.exe') -PathType Leaf) {
            return $resolved
        }
    }
    throw 'status line 需要 Git for Windows 的 Git Bash。請先安裝：https://git-scm.com/download/win'
}

# 先驗證相依，再安裝原生 CLI，最後才遷移舊 npm 套件及部署設定。
function Install-ClaudeCode {
    Write-Host '=== Step 1: status line 相依套件 ===' -ForegroundColor Cyan
    Update-CliInstallPath
    $statuslineInstaller = Join-Path $PSScriptRoot 'install-statusline.ps1'
    foreach ($source in @($statuslineInstaller, (Join-Path $PSScriptRoot 'statusline-command.sh'),
        (Join-Path $PSScriptRoot 'hooks'))) {
        if (-not (Test-Path -LiteralPath $source)) { throw "找不到 status line 來源：$source" }
    }
    $gitBash = Find-ClaudeGitBash
    Initialize-CliNode
    Invoke-CliNative $gitBash @('--noprofile', '--norc', '-c', 'node --version') | Out-Host
    $nodeProbe = 'node -e ''const value={x:1}; if ((value?.x ?? 0) !== 1) process.exit(1)'''
    try {
        Invoke-CliNative $gitBash @('--noprofile', '--norc', '-c', $nodeProbe) | Out-Host
    } catch {
        throw "Git Bash 中的 Node.js 無法執行 status line 所需的 ?. 與 ?? 語法；請用原安裝方式更新 Node.js 後重跑。$_"
    }

    Write-Host '=== Step 2: Claude Code 原生安裝 ===' -ForegroundColor Cyan
    $installerPath = Join-Path ([IO.Path]::GetTempPath()) ('claude-install-' + [guid]::NewGuid().ToString('N') + '.ps1')
    try {
        Invoke-WebRequest -UseBasicParsing -Uri 'https://claude.ai/install.ps1' -OutFile $installerPath -ErrorAction Stop
        $powershell = Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'
        Invoke-CliNative $powershell @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $installerPath) | Out-Host
    } finally {
        if (Test-Path -LiteralPath $installerPath) { Remove-Item -LiteralPath $installerPath -Force }
    }
    $nativeDirectory = Join-Path $env:USERPROFILE '.local\bin'
    $nativeExecutable = Join-Path $nativeDirectory 'claude.exe'
    if (-not (Test-Path -LiteralPath $nativeExecutable -PathType Leaf)) { throw "找不到原生執行檔：$nativeExecutable" }
    Assert-CliVersion $nativeExecutable 'Claude Code'
    Register-CliUserPath $nativeDirectory

    $npmCommand = Get-Command npm.cmd -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($npmCommand) {
        $npmPrefix = (@(Invoke-CliNative $npmCommand.Source @('prefix', '-g')) -join '').Trim()
        if (-not $npmPrefix) { throw 'npm prefix -g 沒有回傳安裝位置。' }
        if (Test-Path -LiteralPath (Join-Path $npmPrefix 'node_modules\@anthropic-ai\claude-code\package.json') -PathType Leaf) {
            Write-Host '  [!] 原生版已驗證，移除目前 npm prefix 的舊 Claude 套件...' -ForegroundColor Yellow
            Invoke-CliNative $npmCommand.Source @('uninstall', '-g', '@anthropic-ai/claude-code') | Out-Host
        }
    }
    Assert-CliCommandSource 'claude' $nativeDirectory

    Write-Host '=== Step 3: status line ===' -ForegroundColor Cyan
    $global:LASTEXITCODE = 0
    & $statuslineInstaller
    $statuslineExitCode = $LASTEXITCODE
    if ($statuslineExitCode -ne 0) { throw "status line 部署失敗（exit $statuslineExitCode）。" }
    Write-Host '[OK] Claude Code 與 status line 安裝完成。' -ForegroundColor Green
}

if ($MyInvocation.InvocationName -ne '.') {
    try { Install-ClaudeCode } catch {
        Write-Host "[X] ERROR: $_" -ForegroundColor Red
        exit 1
    }
}
