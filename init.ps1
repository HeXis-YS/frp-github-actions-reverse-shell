Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
trap {
    Write-Output "ERROR: $_"
    Write-Output (($_.ScriptStackTrace -split '\r?\n') -replace '^(.*)$','ERROR: $1')
    Exit 1
}

# Disable Windows Defender
git clone --depth=1 https://github.com/HeXis-YS/windows-defender-remover
./windows-defender-remover/Script_Run.bat

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
    (Get-Content frpc-windows.toml).replace("#ssh ", "") | Set-Content frpc-windows.toml
}

# Show hidden files and file extensions in explorer
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "HideFileExt" -Value 0
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "Hidden" -Value 1

# Remove wallpaper and lock screen background
Set-ItemProperty -Path "HKLM:\Software\Policies\Microsoft\Windows\System" -Name "DisableLogonBackgroundImage" -Value 1
$removewallpapersrc = @"
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
Add-Type -TypeDefinition $removewallpapersrc
[Wallpaper]::RemoveWallpaper()
