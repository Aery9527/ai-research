$localProfile = Join-Path $HOME ".config\powershell\local_profile.ps1"

if (Test-Path $localProfile) {
    . $localProfile
}
