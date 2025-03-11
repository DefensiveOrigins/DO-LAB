#Disable first run prompts
# Disable First Run
New-Item -Path "HKLM:\Software\Policies\Google\Chrome" -Force | Out-Null
New-ItemProperty -Path "HKLM:\Software\Policies\Google\Chrome" -Name "SuppressFirstRunDefaultBrowserPrompt" -Value 1 -PropertyType DWord -Force
New-ItemProperty -Path "HKLM:\Software\Policies\Google\Chrome" -Name "FirstRunTabs" -Value "" -PropertyType String -Force
New-ItemProperty -Path "HKLM:\Software\Policies\Google\Chrome" -Name "SigninAllowed" -Value 0 -PropertyType DWord -Force
New-ItemProperty -Path "HKLM:\Software\Policies\Google\Chrome" -Name "MetricsReportingEnabled" -Value 0 -PropertyType DWord -Force

# mitigate for  user based policies
New-Item -Path "HKCU:\Software\Policies\Google\Chrome" -Force | Out-Null
New-ItemProperty -Path "HKCU:\Software\Policies\Google\Chrome" -Name "SuppressFirstRunDefaultBrowserPrompt" -Value 1 -PropertyType DWord -Force

# elimiante google account sign in prompt
New-ItemProperty -Path "HKLM:\Software\Policies\Google\Chrome" -Name "BrowserSignin" -Value 0 -PropertyType DWord -Force

