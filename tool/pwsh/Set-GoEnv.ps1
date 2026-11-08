$env:GO_BIN_HOME = Join-Path $HOME "go\bin"
if ($env:PATH -notlike "*$env:GO_BIN_HOME*") {
    $env:PATH = "$env:GO_BIN_HOME;$env:PATH"
}

#$env:GOCACHE = "C:\Users\aerylin\GolandProjects\.gocache"
