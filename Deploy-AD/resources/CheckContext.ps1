param (
    [string]$HostName
)

if (-not $HostName) {
    Write-Host "No hostname provided. Exiting..."
    exit
}

if ($env:COMPUTERNAME -ne $HostName) {
    Write-Host "Wrong system. Expected: $HostName, Found: $env:COMPUTERNAME. Exiting..."
    pause
    exit
}

if ($env:USERNAME -ne "DOADMIN" -or $env:USERDOMAIN -ne "DOAZLAB") {
    Write-Host "Wrong user. Expected: DOAZLAB\DOADMIN, Found: $env:USERDOMAIN\$env:USERNAME. Exiting..."
    pause
    exit
}

Write-Host "Running on correct system: $env:COMPUTERNAME as $env:USERDOMAIN\$env:USERNAME"
