# Define registry path
$edgeRegPath = "HKLM:\SOFTWARE\Policies\Microsoft\Edge"

# Ensure the registry path exists
if (!(Test-Path $edgeRegPath)) {
    New-Item -Path $edgeRegPath -Force | Out-Null
}

# Set the registry keys to disable first run experience
Set-ItemProperty -Path $edgeRegPath -Name "HideFirstRunExperience" -Type DWord -Value 1
Set-ItemProperty -Path $edgeRegPath -Name "PreventFirstRunPage" -Type DWord -Value 1

