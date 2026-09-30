
# All tool/PowerShell scripts are deployed together into $HOME\.config\powershell,
# so sibling scripts are looked up there rather than via $PSScriptRoot.
$ToolRoot = Join-Path $HOME ".config\powershell"

# workspace

function aws { # golang workspace: GolandProjects
    cd (Join-Path $HOME "AeryProjects")
}

function gws { # golang workspace: GolandProjects
    cd (Join-Path $HOME "GolandProjects")
}

function jws { # java workspace: IdeaProjects
    cd (Join-Path $HOME "IdeaProjects")
}

# agent cli

function acc {
    . "$ToolRoot\Set-DevEnv.ps1"
    . "$ToolRoot\Exe-CC.ps1" @args
}

function agc {
    . "$ToolRoot\Set-DevEnv.ps1"
    . "$ToolRoot\Exe-GC.ps1" @args
}

function acx {
    . "$ToolRoot\Set-DevEnv.ps1"
    . "$ToolRoot\Exe-CX.ps1" @args
}

# golang cli

function gcc {
    . "$ToolRoot\Set-DevEnv.ps1"
    . "$ToolRoot\Set-GoEnv.ps1"
    . "$ToolRoot\Set-GoVersion.ps1"
    . "$ToolRoot\Exe-CC.ps1" @args
}

function ggc {
    . "$ToolRoot\Set-DevEnv.ps1"
    . "$ToolRoot\Set-GoEnv.ps1"
    . "$ToolRoot\Set-GoVersion.ps1"
    . "$ToolRoot\Exe-GC.ps1" @args
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

function jgc {
    . "$ToolRoot\Set-DevEnv.ps1"
    . "$ToolRoot\Set-JavaEnv.ps1"
    . "$ToolRoot\Set-JavaVersion.ps1"
    . "$ToolRoot\Exe-GC.ps1" @args
}

function jcx {
    . "$ToolRoot\Set-DevEnv.ps1"
    . "$ToolRoot\Set-JavaEnv.ps1"
    . "$ToolRoot\Set-JavaVersion.ps1"
    . "$ToolRoot\Exe-CX.ps1" @args
}
