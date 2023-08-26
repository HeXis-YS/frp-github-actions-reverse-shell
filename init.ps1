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

# Disable password complexity requirements
secedit /export /cfg C:\secpol.cfg
(Get-Content C:\secpol.cfg).replace("PasswordComplexity = 1", "PasswordComplexity = 0") | Set-Content C:\secpol.cfg
secedit /configure /db c:\windows\security\local.sdb /cfg C:\secpol.cfg /areas SECURITYPOLICY
rm -force C:\secpol.cfg -confirm:$false

# Install OpenSSH
if ($env:INIT_SSH -eq "true") {
    Write-Output 'Installing OpenSSH Server'
    Get-WindowsCapability -Online | Where-Object Name -like 'OpenSSH.Server*' | Add-WindowsCapability -Online
    Start-Service sshd
    (Get-Content frpc-windows.ini).replace("#ssh ", "") | Set-Content frpc-windows.ini
}

# Show hidden files and file extensions in explorer
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "HideFileExt" -Value 0
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "Hidden" -Value 1

# Remove wallpaper
$setwallpapersrc = @"
using System.Runtime.InteropServices;
public class Wallpaper
{
  [DllImport("user32.dll", SetLastError = true, CharSet = CharSet.Auto)]
  private static extern int SystemParametersInfo(int uAction, int uParam, string lpvParam, int fuWinIni);
  public static void RemoveWallpaper()
  {
    SystemParametersInfo(20, 0, "", 3);
  }
}
"@
Add-Type -TypeDefinition $setwallpapersrc
[Wallpaper]::RemoveWallpaper()
