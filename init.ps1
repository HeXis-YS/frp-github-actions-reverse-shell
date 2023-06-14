Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
trap {
    Write-Output "ERROR: $_"
    Write-Output (($_.ScriptStackTrace -split '\r?\n') -replace '^(.*)$','ERROR: $1')
    Exit 1
}

# Disable Windows Defender
./AdvancedRun.exe -oC:\Windows -p"AdvancedRun.exe" -y
foreach($service in "WdNisSvc", "WinDefend", "Sense", "WdnisDrv", "wdfilter", "wdboot") {
    AdvancedRun.exe /EXEFilename "C:\Windows\System32\net.exe" /CommandLine "STOP $service" /RunAs 8 /Run
    AdvancedRun.exe /EXEFilename "C:\Windows\System32\sc.exe" /CommandLine "config $service start=disabled" /RunAs 8 /Run
}
AdvancedRun.exe /EXEFilename "C:\Windows\System32\reg.exe" /CommandLine "add "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows Defender" /v DisableAntiSpyware /t REG_DWORD /d 1 /f" /RunAs 8 /Run /WaitProcess 1
AdvancedRun.exe /EXEFilename "C:\Windows\System32\reg.exe" /CommandLine "add "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows Defender" /v DisableAntiVirus /t REG_DWORD /d 1 /f" /RunAs 8 /Run /WaitProcess 1

# disable password complexity requirements
secedit /export /cfg c:\secpol.cfg
(gc C:\secpol.cfg).replace("PasswordComplexity = 1", "PasswordComplexity = 0") | Out-File C:\secpol.cfg
secedit /configure /db c:\windows\security\local.sdb /cfg c:\secpol.cfg /areas SECURITYPOLICY
rm -force c:\secpol.cfg -confirm:$false

# install OpenSSH
if ($env:INIT_SSH -eq "true") {
    Get-WindowsCapability -Online | Where-Object Name -like 'OpenSSH.Server*' | Add-WindowsCapability -Online
    Start-Service sshd
}
