Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
trap {
    Write-Output "ERROR: $_"
    Write-Output (($_.ScriptStackTrace -split '\r?\n') -replace '^(.*)$','ERROR: $1')
    Exit 1
}

# Disable Windows Defender
pushd D:\
git clone --depth 1 --single-branch --no-tags https://github.com/HeXis-YS/windows-defender-remover
./windows-defender-remover/Script_Run.bat
# rm windows-defender-remover -r -fo
popd

# Install OpenSSH
if ($env:INIT_SSH -eq "true") {
    Write-Output 'Installing OpenSSH Server'
    Get-WindowsCapability -Online | Where-Object Name -like 'OpenSSH.Server*' | Add-WindowsCapability -Online
    Start-Service sshd
    (Get-Content frpc-windows.toml).replace("#ssh ", "") | Set-Content frpc-windows.toml
}

# Recover classic right-click menu
REG ADD "HKCU\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32" /f /ve
