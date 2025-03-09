# Author: Roberto Rodriguez (@Cyb3rWard0g)
# License: GPL-3.0

[CmdletBinding()]
param (
    [Parameter(Mandatory=$false)]
    [string]$SetupType
)

# Install DSC Modules
& .\Install-DSC-Modules.ps1 -SetupType $SetupType

# Custom Settings applied
& .\Prepare-Box.ps1

# Windows Security Audit Categories
if ($SetupType -eq 'DC')
{
    & .\Enable-WinAuditCategories.ps1 -SetDC
}
else
{
    & .\Enable-WinAuditCategories.ps1
}

# ADD RSAT 
if ($SetupType -eq 'DC')
{
    Add-WindowsFeature -Name "RSAT-AD-Tools" -IncludeAllSubFeature
}
else
{
    Add-WindowsCapability -Name Rsat.ActiveDirectory.DS-LDS.Tools~~~~0.0.1.0 -Online
}

# Quiet SM
if ($SetupType -eq 'DC')
{
    & .\Set-ServerManager.ps1
}

#Set Edge FRU
& .\Set-EdgeFRU.ps1

# PowerShell Logging
& .\Enable-PowerShell-Logging.ps1

# Set SACLs
& .\Set-SACLs.ps1

# Set Wallpaper
& .\Set-WallPaper.ps1

# Set Shortcuts
& .\Add-Shortcuts.ps1

# Add browsers
if ($SetupType -eq 'DC')
{
}
else
{
    & .\Add-Browsers.ps1
}

# Rmove NEws/Add bar
if ($SetupType -eq 'DC')
{
}
else
{
    reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\Windows Feeds" /v "EnableFeeds" /t REG_DWORD /d 0 /f
    Stop-Process -Name explorer -Force
}
