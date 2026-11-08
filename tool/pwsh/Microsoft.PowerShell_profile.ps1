$localProfile = Join-Path $HOME ".config\pwsh\local_profile.ps1"

if (Test-Path $localProfile) {
    . $localProfile
}
