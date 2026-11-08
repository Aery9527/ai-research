
# All tool/pwsh scripts are deployed together into $HOME\.config\powershell,
# so sibling scripts are looked up there rather than via $PSScriptRoot.
$ToolRoot = Join-Path $HOME ".config\powershell"

# 列出包含隱藏項目的詳細清單，並轉交 PowerShell 查詢參數。
function ll {
    Get-ChildItem -Force @args
}

# workspace

# 此函式會遮蔽同名的 AWS CLI；如需執行外部命令，請指定 aws.exe。
function aws {
    cd (Join-Path $HOME "AeryProjects")
}

function gws { # golang workspace: GolangProjects
    cd (Join-Path $HOME "GolangProjects")
}

function jws { # java workspace: JavaProjects
    cd (Join-Path $HOME "JavaProjects")
}

# agent cli

function acc {
    . "$ToolRoot\Set-DevEnv.ps1"
    . "$ToolRoot\Exe-CC.ps1" @args
}

function acx {
    . "$ToolRoot\Set-DevEnv.ps1"
    . "$ToolRoot\Exe-CX.ps1" @args
}

# golang cli

# 此函式會遮蔽同名的 GCC 編譯器；如需執行外部命令，請指定 gcc.exe。
function gcc {
    . "$ToolRoot\Set-DevEnv.ps1"
    . "$ToolRoot\Set-GoEnv.ps1"
    . "$ToolRoot\Set-GoVersion.ps1"
    . "$ToolRoot\Exe-CC.ps1" @args
}

function gcx {
    . "$ToolRoot\Set-DevEnv.ps1"
    . "$ToolRoot\Set-GoEnv.ps1"
    . "$ToolRoot\Set-GoVersion.ps1"
    . "$ToolRoot\Exe-CX.ps1" @args
}

# java cli

function jcc {
    . "$ToolRoot\Set-DevEnv.ps1"
    . "$ToolRoot\Set-JavaEnv.ps1"
    . "$ToolRoot\Set-JavaVersion.ps1"
    . "$ToolRoot\Exe-CC.ps1" @args
}

function jcx {
    . "$ToolRoot\Set-DevEnv.ps1"
    . "$ToolRoot\Set-JavaEnv.ps1"
    . "$ToolRoot\Set-JavaVersion.ps1"
    . "$ToolRoot\Exe-CX.ps1" @args
}
