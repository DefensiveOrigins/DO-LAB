

New-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\ServerManager" -Name "DoNotOpenServerManagerAtLogon" -Value 1 -PropertyType DWORD -Force
