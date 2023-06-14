Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
trap {
    Write-Output "ERROR: $_"
    Write-Output (($_.ScriptStackTrace -split '\r?\n') -replace '^(.*)$','ERROR: $1')
    Exit 1
}

# Install frp
mkdir -Force frp | Out-Null
Push-Location frp

if (!(Test-Path frps.exe)) {
    Write-Output 'Downloading frp...'
    (New-Object System.Net.WebClient).DownloadFile(
        'https://github.com/fatedier/frp/releases/download/v0.49.0/frp_0.49.0_windows_amd64.zip',
        "$PWD/frp.zip")
    Write-Output 'Extracting frp...'
    tar xf frp.zip --strip-components=1
}

Pop-Location

# when running in CI override the frpc tls files.
if (Test-Path env:FRPC_TLS_CA_CERTIFICATE) {
    Write-Output 'Configuring certificates...'
    mkdir -Force ca | Out-Null
    Set-Content -Encoding Ascii ca/github-key.pem $env:FRPC_TLS_KEY
    Set-Content -Encoding Ascii ca/github.pem $env:FRPC_TLS_CERTIFICATE
    Set-Content -Encoding Ascii ca/ca.pem $env:FRPC_TLS_CA_CERTIFICATE
}

# set password when requested.
if (Test-Path env:RUNNER_PASSWORD) {
    Write-Output "Setting the $env:USERNAME user password..."
    Get-LocalUser $env:USERNAME `
        | Set-LocalUser `
            -Password (
                ConvertTo-SecureString `
                    -AsPlainText `
                    -Force `
                    $env:RUNNER_PASSWORD
            )
}

Write-Output 'Running frpc...'
./frp/frpc -c frpc-windows.ini 2>&1 | Select-Object {$_ -replace '[0-9\.]+:7000','***:7000'}; cmd /c exit 0
