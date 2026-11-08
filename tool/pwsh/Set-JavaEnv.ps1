$env:MAVEN_HOME = Join-Path $HOME ".maven\apache-maven-3.9.16"
if ($env:PATH -notlike "*$env:MAVEN_HOME*") {
    $env:PATH = "$env:MAVEN_HOME\bin;$env:PATH"
}
