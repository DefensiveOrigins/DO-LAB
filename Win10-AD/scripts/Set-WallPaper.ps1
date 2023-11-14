# Author: Roberto Rodriguez (@Cyb3rWard0g)
# License: GPL-3.0

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

Resolve-DnsName github.com
Resolve-DnsName raw.githubusercontent.com
Resolve-DnsName live.sysinternals.com

$wc = new-object System.Net.WebClient
# Download BgInfo
$wc.DownloadFile('http://live.sysinternals.com/bginfo.exe', 'C:\ProgramData\bginfo.exe')

# Copy Wallpaper
$wc.DownloadFile('https://raw.githubusercontent.com/DefensiveOrigins/DO-LAB/main/Win10-AD/resources/APT1.jpg', 'C:\ProgramData\APT1.jpg')
$wc.DownloadFile('https://raw.githubusercontent.com/DefensiveOrigins/DO-LAB/main/Win10-AD/resources/DOLAB.gif', 'C:\ProgramData\DOLAB.gif')

# Copy BGInfo config
$wc.DownloadFile('https://raw.githubusercontent.com/DefensiveOrigins/DO-LAB/main/Win10-AD/resources/dolabs.bgi', 'C:\ProgramData\dolabs.bgi')

# Set Run Key
New-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" -Name "BgInfo" -Value "C:\ProgramData\bginfo.exe C:\ProgramData\dolabs.bgi /silent /timer:0 /nolicprompt" -PropertyType "String" -force