$env:GO_HOME = Join-Path $HOME "sdk\go1.26.0\bin"
if ($env:PATH -notlike "*$env:GO_HOME*") {
    $env:PATH = "$env:GO_HOME;$env:PATH"
}
