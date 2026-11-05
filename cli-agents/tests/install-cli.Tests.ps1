#Requires -Version 5.1

$installerRoot = Split-Path -Parent $PSScriptRoot
. (Join-Path $installerRoot 'install-cli-common.ps1')

Describe '安裝共用檢查' {
    BeforeEach {
        $script:savedPath = $env:Path
        $script:nodeAvailable = $true
        $script:npmAvailable = $true
        $script:wingetAvailable = $false
        Mock Get-Command {
            if ($Name -eq 'node.exe' -and $script:nodeAvailable) { return [pscustomobject]@{ Source = 'C:\fixture\node.exe' } }
            if ($Name -eq 'npm.cmd' -and $script:npmAvailable) { return [pscustomobject]@{ Source = 'C:\fixture\npm.cmd' } }
            if ($Name -eq 'winget.exe' -and $script:wingetAvailable) { return [pscustomobject]@{ Source = 'C:\fixture\winget.exe' } }
        } -ParameterFilter { $Name -in @('node.exe', 'npm.cmd', 'winget.exe') }
        $script:wingetAction = ''
        Mock Invoke-CliNative {
            if ($FilePath -like '*winget.exe') {
                if ($script:wingetAction -eq 'fail') { throw 'winget install failed (exit 5)' }
                if ($script:wingetAction -eq 'install') {
                    $script:nodeAvailable = $true
                    $script:npmAvailable = $true
                }
            }
            '22.0.0'
        }
    }
    AfterEach { $env:Path = $script:savedPath }

    It '既有 Node/npm 可用時不要求 winget，也不更新相依套件' {
        Initialize-CliNode -RequireNpm
        Assert-MockCalled Invoke-CliNative -Exactly 0 -ParameterFilter { $FilePath -like '*winget.exe' } -Scope It
    }
    It 'status line 只需要 Node，不要求 npm' {
        $script:npmAvailable = $false
        Initialize-CliNode
        Assert-MockCalled Invoke-CliNative -Exactly 1 -ParameterFilter { $FilePath -like '*node.exe' } -Scope It
    }
    It '缺 Node/npm 與 winget 時回報可操作的錯誤' {
        $script:nodeAvailable = $false
        $script:npmAvailable = $false
        { Initialize-CliNode -RequireNpm } | Should Throw '沒有 winget'
    }
    It '不完整的既有環境不會被另一套 Node 覆蓋' {
        $script:npmAvailable = $false
        { Initialize-CliNode -RequireNpm } | Should Throw '安裝不完整'
        Assert-MockCalled Invoke-CliNative -Exactly 0 -Scope It
    }
    It 'winget 安裝失敗會停止，不再報已是最新版' {
        $script:nodeAvailable = $false
        $script:npmAvailable = $false
        $script:wingetAvailable = $true
        $script:wingetAction = 'fail'
        { Initialize-CliNode -RequireNpm } | Should Throw 'exit 5'
    }
    It 'winget 成功但指令仍缺少時不報成功' {
        $script:nodeAvailable = $false
        $script:npmAvailable = $false
        $script:wingetAvailable = $true
        { Initialize-CliNode -RequireNpm } | Should Throw '仍找不到'
    }
    It '安裝後重新解析 Node/npm 再驗證版本' {
        $script:nodeAvailable = $false
        $script:npmAvailable = $false
        $script:wingetAvailable = $true
        $script:wingetAction = 'install'
        Initialize-CliNode -RequireNpm
        Assert-MockCalled Invoke-CliNative -Exactly 1 -ParameterFilter { $FilePath -like '*node.exe' } -Scope It
        Assert-MockCalled Invoke-CliNative -Exactly 1 -ParameterFilter { $FilePath -like '*npm.cmd' } -Scope It
    }
    It 'PATH 保留程序專用路徑且可重複合併而不增加重複項目' {
        $env:Path = 'C:\fixture-nvm;C:\fixture-nvm'
        Update-CliInstallPath
        $env:Path.Split(';')[0] | Should Be 'C:\fixture-nvm'
        @($env:Path.Split(';') | Where-Object { $_ -eq 'C:\fixture-nvm' }).Count | Should Be 1
        $mergedPath = $env:Path
        Update-CliInstallPath
        $env:Path | Should Be $mergedPath
    }
}

Describe '原生程式結束碼與來源驗證' {
    It '非零結束碼傳為失敗並恢復 ErrorActionPreference' {
        $savedPreference = $ErrorActionPreference
        { Invoke-CliNative "$env:SystemRoot\System32\cmd.exe" @('/d', '/c', 'exit 9') } | Should Throw 'exit 9'
        $ErrorActionPreference | Should Be $savedPreference
    }
    It '找不到程式時不得因 LASTEXITCODE 重設為零而假成功' {
        { Invoke-CliNative (Join-Path $TestDrive 'missing.exe') } | Should Throw 'missing.exe'
    }
    It '零結束碼但沒有版本時不得假成功' {
        Mock Invoke-CliNative { 'not installed' }
        { Assert-CliVersion 'fixture.exe' 'CLI' } | Should Throw '沒有回傳有效版本'
    }
    It '其他安裝位置遮蔽指令時停止' {
        Mock Get-Command { [pscustomobject]@{ CommandType = 'Application'; Source = 'C:\other\codex.exe' } } -ParameterFilter { $Name -eq 'codex' }
        { Assert-CliCommandSource 'codex' 'C:\expected' } | Should Throw '被其他安裝遮蔽'
    }
    It 'alias 遮蔽指令時停止' {
        Mock Get-Command { [pscustomobject]@{ CommandType = 'Alias'; Source = '' } } -ParameterFilter { $Name -eq 'codex' }
        { Assert-CliCommandSource 'codex' 'C:\expected' } | Should Throw 'alias'
    }
}

Describe 'Claude/Codex 安裝與遷移' {
    $script:fixtureRoot = Join-Path $TestDrive '安裝來源'
    New-Item -ItemType Directory -Path (Join-Path $script:fixtureRoot 'claude-code'), (Join-Path $script:fixtureRoot 'codex') -Force | Out-Null
    Copy-Item (Join-Path $installerRoot 'install-cli-common.ps1') $script:fixtureRoot
    Copy-Item (Join-Path $installerRoot 'claude-code\install-cc.ps1') (Join-Path $script:fixtureRoot 'claude-code')
    Copy-Item (Join-Path $installerRoot 'codex\install-cx.ps1') (Join-Path $script:fixtureRoot 'codex')
    . (Join-Path $script:fixtureRoot 'claude-code\install-cc.ps1')
    . (Join-Path $script:fixtureRoot 'codex\install-cx.ps1')
    BeforeEach {
        $script:savedProfile = $env:USERPROFILE
        $script:savedPath = $env:Path
        $script:caseRoot = Join-Path $TestDrive ([guid]::NewGuid().ToString('N'))
        $env:USERPROFILE = Join-Path $script:caseRoot '使用者'
        $script:prefix = Join-Path $script:caseRoot 'npm prefix'
        $script:nativeDirectory = Join-Path $env:USERPROFILE '.local\bin'
        foreach ($directory in @($script:nativeDirectory, $script:prefix,
            (Join-Path $script:fixtureRoot 'claude-code\hooks'), (Join-Path $script:fixtureRoot 'codex\pets'))) {
            New-Item -ItemType Directory -Path $directory -Force | Out-Null
        }
        Set-Content (Join-Path $script:fixtureRoot 'claude-code\statusline-command.sh') 'fixture' -Encoding UTF8
        Set-Content (Join-Path $script:fixtureRoot 'claude-code\install-statusline.ps1') 'Set-Content -LiteralPath (Join-Path $env:USERPROFILE status-deployed) -Value OK' -Encoding UTF8
        Set-Content (Join-Path $script:fixtureRoot 'codex\pets\fixture.txt') 'new pet' -Encoding UTF8
        Set-Content (Join-Path $script:nativeDirectory 'claude.exe') 'fixture' -Encoding UTF8
        Set-Content (Join-Path $script:prefix 'codex.cmd') 'fixture' -Encoding UTF8
        Mock Initialize-CliNode { }
        $script:scenario = ''
        Mock Find-ClaudeGitBash { if ($script:scenario -eq 'no-bash') { throw 'missing Git Bash' }; 'C:\fixture\bash.exe' }
        Mock Register-CliUserPath { if ($script:scenario -eq 'path-failure') { throw 'cannot save user PATH' } }
        Mock Get-Command {
            if ($Name -eq 'npm.cmd') { return [pscustomobject]@{ Source = 'C:\fixture\npm.cmd' } }
            if ($Name -eq 'claude') { return [pscustomobject]@{ CommandType = 'Application'; Source = (Join-Path $script:nativeDirectory 'claude.exe') } }
            if ($Name -eq 'codex') { return [pscustomobject]@{ CommandType = 'ExternalScript'; Source = (Join-Path $script:prefix 'codex.ps1') } }
        } -ParameterFilter { $Name -in @('npm.cmd', 'claude', 'codex') }
        $script:downloadedInstaller = $null
        Mock Invoke-WebRequest {
            $script:downloadedInstaller = $OutFile
            Set-Content -LiteralPath $OutFile -Value '# mocked installer' -Encoding UTF8
        }
        Mock Invoke-CliNative {
            if ($script:scenario -eq 'bash-node-failure' -and $FilePath -like '*bash.exe') { throw 'node unavailable in bash' }
            if ($script:scenario -eq 'node-syntax-failure' -and $FilePath -like '*bash.exe' -and $ArgumentList[-1].Contains('value?.x')) { throw 'SyntaxError' }
            if ($script:scenario -eq 'native-failure' -and $FilePath -like '*powershell.exe') { throw 'native install failed' }
            if ($script:scenario -eq 'native-version-failure' -and $FilePath -like '*claude.exe') { throw 'cannot run claude' }
            if ($script:scenario -eq 'uninstall-failure' -and $ArgumentList[0] -eq 'uninstall') { throw 'uninstall failed' }
            if ($script:scenario -eq 'engine-failure' -and $ArgumentList[0] -eq 'install') { throw 'EBADENGINE' }
            if ($script:scenario -eq 'codex-failure' -and $FilePath -like '*codex.cmd') { throw 'cannot run codex' }
            if ($ArgumentList[0] -eq 'prefix') { return $script:prefix }
            if ($ArgumentList[0] -eq '--version' -or $FilePath -like '*bash.exe') { return '22.1.0' }
        }
    }
    AfterEach {
        $env:USERPROFILE = $script:savedProfile
        $env:Path = $script:savedPath
    }
    It 'Claude 使用官方下載網址與獨立程序，最後部署 status line' {
        Install-ClaudeCode
        Assert-MockCalled Invoke-WebRequest -Exactly 1 -ParameterFilter { $Uri -eq 'https://claude.ai/install.ps1' } -Scope It
        Assert-MockCalled Invoke-CliNative -Exactly 1 -ParameterFilter { $FilePath -like '*powershell.exe' -and $ArgumentList -contains '-File' } -Scope It
        Assert-MockCalled Invoke-CliNative -Exactly 0 -ParameterFilter { $ArgumentList[0] -eq 'install' -and $FilePath -like '*npm.cmd' } -Scope It
        Assert-MockCalled Register-CliUserPath -Exactly 1 -ParameterFilter { $Directory -eq $script:nativeDirectory } -Scope It
        Test-Path (Join-Path $env:USERPROFILE 'status-deployed') | Should Be $true
    }
    It '缺 Git Bash 時不安裝 Node 或下載 Claude' {
        $script:scenario = 'no-bash'
        { Install-ClaudeCode } | Should Throw 'Git Bash'
        Assert-MockCalled Initialize-CliNode -Exactly 0 -Scope It
        Assert-MockCalled Invoke-WebRequest -Exactly 0 -Scope It
    }
    It 'Git Bash 無法執行 Node 時不下載 Claude' {
        $script:scenario = 'bash-node-failure'
        { Install-ClaudeCode } | Should Throw 'node unavailable'
        Assert-MockCalled Invoke-WebRequest -Exactly 0 -Scope It
    }
    It '原生安裝失敗時不移除舊 npm Claude，且清理下載的腳本' {
        $oldPackage = Join-Path $script:prefix 'node_modules\@anthropic-ai\claude-code'
        New-Item -ItemType Directory -Path $oldPackage -Force | Out-Null
        Set-Content (Join-Path $oldPackage 'package.json') '{}' -Encoding UTF8
        $script:scenario = 'native-failure'
        { Install-ClaudeCode } | Should Throw 'native install failed'
        Assert-MockCalled Invoke-CliNative -Exactly 0 -ParameterFilter { $ArgumentList[0] -eq 'uninstall' } -Scope It
        Assert-MockCalled Invoke-WebRequest -Exactly 1 -Scope It
        Assert-MockCalled Register-CliUserPath -Exactly 0 -Scope It
        Test-Path -LiteralPath $script:downloadedInstaller | Should Be $false
        Test-Path (Join-Path $env:USERPROFILE 'status-deployed') | Should Be $false
    }
    It 'Node 有版本號但不支援 status line 語法時，在下載前停止' {
        $script:scenario = 'node-syntax-failure'
        { Install-ClaudeCode } | Should Throw 'SyntaxError'
        Assert-MockCalled Invoke-WebRequest -Exactly 0 -Scope It
    }
    It '原生安裝回傳成功但無法執行時保留舊 npm Claude' {
        $oldPackage = Join-Path $script:prefix 'node_modules\@anthropic-ai\claude-code'
        New-Item -ItemType Directory -Path $oldPackage -Force | Out-Null
        Set-Content (Join-Path $oldPackage 'package.json') '{}' -Encoding UTF8
        $script:scenario = 'native-version-failure'
        { Install-ClaudeCode } | Should Throw 'cannot run claude'
        Assert-MockCalled Invoke-CliNative -Exactly 0 -ParameterFilter { $ArgumentList[0] -eq 'uninstall' } -Scope It
        Test-Path (Join-Path $oldPackage 'package.json') | Should Be $true
    }
    It '原生版驗證成功後才移除目前 npm prefix 的舊套件' {
        $oldPackage = Join-Path $script:prefix 'node_modules\@anthropic-ai\claude-code'
        New-Item -ItemType Directory -Path $oldPackage -Force | Out-Null
        Set-Content (Join-Path $oldPackage 'package.json') '{}' -Encoding UTF8
        Install-ClaudeCode
        Assert-MockCalled Invoke-CliNative -Exactly 1 -ParameterFilter { $ArgumentList[0] -eq 'uninstall' -and $ArgumentList -contains '@anthropic-ai/claude-code' } -Scope It
    }
    It 'Claude 持久 PATH 無法寫入時保留舊 npm 套件' {
        $oldPackage = Join-Path $script:prefix 'node_modules\@anthropic-ai\claude-code'
        New-Item -ItemType Directory -Path $oldPackage -Force | Out-Null
        Set-Content (Join-Path $oldPackage 'package.json') '{}' -Encoding UTF8
        $script:scenario = 'path-failure'
        { Install-ClaudeCode } | Should Throw 'cannot save user PATH'
        Assert-MockCalled Invoke-CliNative -Exactly 0 -ParameterFilter { $ArgumentList[0] -eq 'uninstall' } -Scope It
        Test-Path (Join-Path $oldPackage 'package.json') | Should Be $true
    }
    It 'npm 移除失敗時停止，不部署 status line' {
        $oldPackage = Join-Path $script:prefix 'node_modules\@anthropic-ai\claude-code'
        New-Item -ItemType Directory -Path $oldPackage -Force | Out-Null
        Set-Content (Join-Path $oldPackage 'package.json') '{}' -Encoding UTF8
        $script:scenario = 'uninstall-failure'
        { Install-ClaudeCode } | Should Throw 'uninstall failed'
        Test-Path (Join-Path $env:USERPROFILE 'status-deployed') | Should Be $false
    }
    It 'Codex 以 npm 安裝且驗證後複製 pets，保留額外檔案' {
        $petDestination = Join-Path $env:USERPROFILE '.codex\pets'
        New-Item -ItemType Directory -Path $petDestination -Force | Out-Null
        Set-Content (Join-Path $petDestination 'keep.txt') 'keep' -Encoding UTF8
        Install-CodexCli
        Assert-MockCalled Invoke-CliNative -Exactly 1 -ParameterFilter { $ArgumentList[0] -eq 'install' -and $ArgumentList -contains '--engine-strict' -and $ArgumentList -contains '--include=optional' } -Scope It
        (Get-Content (Join-Path $petDestination 'fixture.txt')) | Should Be 'new pet'
        Test-Path (Join-Path $petDestination 'keep.txt') | Should Be $true
    }
    It 'Codex npm 安裝失敗時不部署 pets 或變更持久 PATH' {
        $script:scenario = 'engine-failure'
        { Install-CodexCli } | Should Throw 'EBADENGINE'
        Assert-MockCalled Register-CliUserPath -Exactly 0 -Scope It
        Test-Path (Join-Path $env:USERPROFILE '.codex\pets') | Should Be $false
    }
    It 'Codex 安裝回傳成功但執行檔不能執行時不部署 pets' {
        $script:scenario = 'codex-failure'
        { Install-CodexCli } | Should Throw 'cannot run codex'
        Test-Path (Join-Path $env:USERPROFILE '.codex\pets') | Should Be $false
    }
}

Describe 'CLI 入口失敗結束碼' {
    It '兩支腳本缺少部署來源時均向呼叫端回傳非零碼' {
        $entryRoot = Join-Path $TestDrive 'entry'
        New-Item -ItemType Directory -Path (Join-Path $entryRoot 'claude-code'), (Join-Path $entryRoot 'codex') -Force | Out-Null
        Copy-Item (Join-Path $installerRoot 'install-cli-common.ps1') $entryRoot
        Copy-Item (Join-Path $installerRoot 'claude-code\install-cc.ps1') (Join-Path $entryRoot 'claude-code')
        Copy-Item (Join-Path $installerRoot 'codex\install-cx.ps1') (Join-Path $entryRoot 'codex')
        $powershellExecutable = Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'
        foreach ($entry in @('claude-code\install-cc.ps1', 'codex\install-cx.ps1')) {
            $output = & $powershellExecutable -NoProfile -ExecutionPolicy Bypass -File (Join-Path $entryRoot $entry)
            $entryExitCode = $LASTEXITCODE
            $entryExitCode | Should Be 1
            ($output -join '') | Should Match 'ERROR'
        }
    }
}
