param (
    [string]$HostName
)

# Check if running as Administrator
$adminCheck = [System.Security.Principal.WindowsIdentity]::GetCurrent()
$isAdmin = (New-Object System.Security.Principal.WindowsPrincipal $adminCheck).IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "`n`nWARN: This script must be run as an Administrator. Exiting...`n`n"
    pause
    Stop-Process -Id $PID
}


if (-not $HostName) {
    Write-Host "No hostname provided. Exiting..."
    exit
}

if ($env:COMPUTERNAME -ne $HostName) {
    Write-Host "`n`nWARN: Wrong system. Expected: $HostName, Found: $env:COMPUTERNAME. Exiting...`n`n"
    pause
    Stop-Process -Id $PID
}

if ($env:USERNAME -ne "DOADMIN" -or $env:USERDOMAIN -ne "DOAZLAB") {
    Write-Host "`n`nWARN: Wrong user. Expected: DOAZLAB\DOADMIN, Found: $env:USERDOMAIN\$env:USERNAME. Exiting...`n`n"
    pause
    Stop-Process -Id $PID
}

Write-Host "`n`nINFO: Running on correct system: $env:COMPUTERNAME as $env:USERDOMAIN\$env:USERNAME with Administrator privileges.`n`n"
