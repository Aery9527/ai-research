# Java 環境變數設定 - 以後要換 Java 版本只改這個檔案
$env:JAVA_HOME = Join-Path $HOME ".jdks\corretto-21.0.11"

if ($env:PATH -notlike "*$env:JAVA_HOME*") {
    $env:PATH = "$env:JAVA_HOME\bin;$env:PATH"
}
