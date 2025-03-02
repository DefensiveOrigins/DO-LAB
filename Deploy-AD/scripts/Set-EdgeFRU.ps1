# Define registry path
$edgeRegPath = "HKLM:\SOFTWARE\Policies\Microsoft\Edge"

# Ensure the registry path exists
if (!(Test-Path $edgeRegPath)) {
    New-Item -Path $edgeRegPath -Force | Out-Null
}

# Set the registry keys to disable first run experience
Set-ItemProperty -Path $edgeRegPath -Name "HideFirstRunExperience" -Type DWord -Value 1
Set-ItemProperty -Path $edgeRegPath -Name "PreventFirstRunPage" -Type DWord -Value 1

### Define blank tab & fav bar
# Define the registry path for Edge policies
$EdgePolicyPath = "HKLM:\SOFTWARE\Policies\Microsoft\Edge"
# Ensure the registry path exists
if (-not (Test-Path $EdgePolicyPath)) {
    New-Item -Path $EdgePolicyPath -Force | Out-Null
}
# Set the homepage to "about:blank"
Set-ItemProperty -Path $EdgePolicyPath -Name "HomepageLocation" -Value "about:blank" -Type String
# Ensure Edge starts with the homepage (instead of restoring previous tabs)
Set-ItemProperty -Path $EdgePolicyPath -Name "RestoreOnStartup" -Value 4 -Type DWord
# Ensure Edge enforces the homepage setting
Set-ItemProperty -Path $EdgePolicyPath -Name "HomepageIsNewTabPage" -Value 0 -Type DWord
# Force a blank new tab page
Set-ItemProperty -Path $EdgePolicyPath -Name "NewTabPageLocation" -Value "about:blank" -Type String
# Ensure Edge enforces the new tab page setting
Set-ItemProperty -Path $EdgePolicyPath -Name "NewTabPageSetFeedType" -Value 0 -Type DWord
# Hide the Favorites Bar
Set-ItemProperty -Path $EdgePolicyPath -Name "FavoritesBarEnabled" -Value 0 -Type DWord

Write-Output "Edge homepage, new tab page, and Favorites Bar settings have been applied for all users."
