# Author: Roberto Rodriguez (@Cyb3rWard0g)
# License: GPL-3.0

New-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\ServerManager" -Name "DoNotOpenServerManagerAtLogon" -Value 1 -PropertyType DWORD -Force
