

## ADD POWERSHELL DESKTOP ICON(ADMIN MODE)
$ShortcutPath = "C:\Users\Public\Desktop\PowerShell (Admin).lnk"
$PowerShellPath = "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe"
$WScriptShell = New-Object -ComObject WScript.Shell
$Shortcut = $WScriptShell.CreateShortcut($ShortcutPath)
$Shortcut.TargetPath = $PowerShellPath
$Shortcut.Arguments = "-Command Start-Process PowerShell -Verb RunAs"
$Shortcut.IconLocation = "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe,0"
$Shortcut.Save()
Write-Host "Shortcut created successfully: $ShortcutPath"


## ADD EVENTLOG DESKTOP ICON(ADMIN MODE)
$ShortcutPath = "C:\Users\Public\Desktop\Event Viewer.lnk"
$EventViewerPath = "$env:SystemRoot\System32\eventvwr.msc"
$WScriptShell = New-Object -ComObject WScript.Shell
$Shortcut = $WScriptShell.CreateShortcut($ShortcutPath)
$Shortcut.TargetPath = $EventViewerPath
$Shortcut.IconLocation = "$env:SystemRoot\System32\eventvwr.msc,0"
$Shortcut.Save()
Write-Host "Shortcut created successfully: $ShortcutPath"

## ADD ICON FOR ADUC
$ShortcutPath = "C:\Users\Public\Desktop\Active Directory Users and Computers.lnk"
$TargetPath = "C:\Windows\System32\dsa.msc"
$WScriptShell = New-Object -ComObject WScript.Shell
$Shortcut = $WScriptShell.CreateShortcut($ShortcutPath)
$Shortcut.TargetPath = $TargetPath
$Shortcut.WorkingDirectory = "C:\Windows\System32"
$Shortcut.Description = "Shortcut to Active Directory Users and Computers"
$Shortcut.IconLocation = "C:\Windows\System32\dsa.msc,0"
$Shortcut.Save()
Write-Host "Shortcut to ADUC created on Public Desktop successfully."

### ADD ICONF OR SSH
$DesktopPath = "C:\Users\Public\Desktop\"
$ShortcutPath = "$DesktopPath\SSH-to-C2.lnk"
$sshCommand = "ssh doadmin@10.0.0.8"
$WScriptShell = New-Object -ComObject WScript.Shell
$Shortcut = $WScriptShell.CreateShortcut($ShortcutPath)
$Shortcut.TargetPath = "cmd.exe"
$Shortcut.Arguments = "/k $sshCommand"
$Shortcut.WorkingDirectory = $DesktopPath
$Shortcut.WindowStyle = 1
$Shortcut.Description = "SSH to C2"
$Shortcut.Save()
Write-Host "Shortcut created at: $ShortcutPath"
