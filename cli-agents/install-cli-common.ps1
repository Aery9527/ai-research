#Requires -Version 5.1

# 合併持久 PATH，保留 nvm 等只存在於目前程序的路徑及其優先順序。
function Update-CliInstallPath {
    param([string[]]$AdditionalPath = @())

    $seen = [Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
    $entries = [Collections.Generic.List[string]]::new()
    $pathValues = @($env:Path,
        [Environment]::GetEnvironmentVariable('Path', 'Machine'),
        [Environment]::GetEnvironmentVariable('Path', 'User')) + $AdditionalPath
    foreach ($value in $pathValues) {
        foreach ($entry in ($value -split ';')) {
            if (-not [string]::IsNullOrWhiteSpace($entry) -and $seen.Add($entry)) {
                $entries.Add($entry)
            }
        }
    }
    $env:Path = $entries -join ';'
}

# 原生程式以結束碼判定成功，避免 PowerShell 5.1 將正常 stderr 當成終止錯誤。
function Invoke-CliNative {
    param([string]$FilePath, [string[]]$ArgumentList = @())

    $previousPreference = $ErrorActionPreference
    try {
        $ErrorActionPreference = 'Continue'
        $global:LASTEXITCODE = 0
        $output = & $FilePath @ArgumentList
        $commandSucceeded = $?
        $commandExitCode = $LASTEXITCODE
    } finally {
        $ErrorActionPreference = $previousPreference
    }
    if (-not $commandSucceeded -or $commandExitCode -ne 0) {
        throw "$FilePath 執行失敗（exit $commandExitCode）。"
    }
    $output
}

# 僅在持久 PATH 缺少安裝目錄時補入使用者範圍，保留既有路徑。
function Register-CliUserPath {
    param([string]$Directory)

    $userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
    $persistentEntries = ($userPath + ';' + [Environment]::GetEnvironmentVariable('Path', 'Machine')) -split ';'
    if ($persistentEntries -notcontains $Directory) {
        $newUserPath = if ([string]::IsNullOrEmpty($userPath)) { $Directory } else { $userPath.TrimEnd(';') + ';' + $Directory }
        [Environment]::SetEnvironmentVariable('Path', $newUserPath, 'User')
    }
    Update-CliInstallPath -AdditionalPath @($Directory)
}

# 只有缺少 Node.js/npm 時才安裝；既有環境由其原本的套件管理器管理。
function Initialize-CliNode {
    param([switch]$RequireNpm)

    Update-CliInstallPath
    $nodeCommand = Get-Command node.exe -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
    $npmCommand = Get-Command npm.cmd -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
    if (-not $nodeCommand -or ($RequireNpm -and -not $npmCommand)) {
        if ($nodeCommand -or $npmCommand) {
            throw 'Node.js/npm 安裝不完整。請用原本的安裝方式修復，或切換至可用的 nvm 版本後重跑。'
        }
        $wingetCommand = Get-Command winget.exe -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
        if (-not $wingetCommand) {
            throw '找不到 Node.js，且沒有 winget。請手動安裝 Node.js LTS 後重跑。'
        }
        Write-Host '  [!] 安裝 Node.js LTS...' -ForegroundColor Yellow
        Invoke-CliNative $wingetCommand.Source @('install', '--exact', '--id', 'OpenJS.NodeJS.LTS',
            '--silent', '--accept-package-agreements', '--accept-source-agreements') | Out-Host
        Update-CliInstallPath
        $nodeCommand = Get-Command node.exe -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
        $npmCommand = Get-Command npm.cmd -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
    }
    if (-not $nodeCommand -or ($RequireNpm -and -not $npmCommand)) {
        throw '安裝後仍找不到所需的 Node.js/npm。請開新終端機確認安裝路徑後重跑。'
    }
    Assert-CliVersion $nodeCommand.Source 'Node.js'
    if ($RequireNpm) { Assert-CliVersion $npmCommand.Source 'npm' }
}

# 執行版本指令，而不是只以套件管理器成功判定 CLI 可用。
function Assert-CliVersion {
    param([string]$FilePath, [string]$Name)

    $version = @(Invoke-CliNative $FilePath @('--version')) -join "`n"
    if ($version -notmatch '\d+\.\d+\.\d+') { throw "$Name 沒有回傳有效版本：$FilePath" }
    Write-Host "  [OK] $Name $($version.Trim()) [$FilePath]" -ForegroundColor Green
}

# 確認使用者輸入裸指令時會解析到本次安裝位置，拒絕 alias/function 或其他安裝來源。
function Assert-CliCommandSource {
    param([string]$Name, [string]$ExpectedDirectory)

    $command = Get-Command $Name -ErrorAction SilentlyContinue | Select-Object -First 1
    if (-not $command -or $command.CommandType -notin @('Application', 'ExternalScript')) {
        throw "$Name 沒有解析到已安裝的執行檔。請檢查 PATH、alias 與 function 後重跑。"
    }
    $actualDirectory = Split-Path -Parent $command.Source
    if ([IO.Path]::GetFullPath($actualDirectory).TrimEnd('\') -ine
        [IO.Path]::GetFullPath($ExpectedDirectory).TrimEnd('\')) {
        throw "$Name 被其他安裝遮蔽：$($command.Source)。請移除衝突安裝或調整 PATH 後重跑。"
    }
    Write-Host "  [OK] $Name 指令來源：$($command.Source)" -ForegroundColor Green
}
