# Author: Roberto Rodriguez @Cyb3rWard0g
# License: GPLv3
# References:
# https://github.com/Azure/azure-quickstart-templates/blob/master/sharepoint-adfs/dsc/ConfigureDCVM.ps1
configuration ADD-DC1-Services {
    param 
    ( 
        [Parameter(Mandatory)]
        [String]$DomainFQDN,

        [Parameter(Mandatory)]
        [System.Management.Automation.PSCredential]$AdminCreds,

        [Parameter(Mandatory)]
        [Object]$DomainUsers
    ) 
    
    Import-DscResource -ModuleName ActiveDirectoryDsc, NetworkingDsc, xPSDesiredStateConfiguration, xDnsServer, ComputerManagementDsc
    
    [String] $DomainNetbiosName = (Get-NetBIOSName -DomainFQDN $DomainFQDN)
    [System.Management.Automation.PSCredential]$DomainCreds = New-Object System.Management.Automation.PSCredential ("${DomainNetbiosName}\$($Admincreds.UserName)", $Admincreds.Password)

    # Handle if there are more than one network adapter.  If there is more than one, use the one named Hyper-V
    $count = Get-NetAdapter | Where-Object Name -Like "Ethernet*" | Measure-Object | Select-Object -ExpandProperty Count
    if ($count -gt 1) {
        # Action if the count is greater than 1
        Write-Host "There are more than one Ethernet adapters."
        $Interface = Get-NetAdapter | Where-Object InterfaceDescription -Like  "Microsoft Hyper-V Network Adapter" | Select-Object -First 1
        Write-Host  $Interface
        $InterfaceAlias = $($Interface.Name)
        Write-Host $InterfaceAlias
    } else {
        # Action if the count is 1 or less
        Write-Host "There is one or fewer Ethernet adapters."
        $Interface = Get-NetAdapter | Where-Object Name -Like "Ethernet*" | Select-Object -First 1
        Write-Host  $Interface
        $InterfaceAlias = $($Interface.Name)
        Write-Host $InterfaceAlias
    }


    $bstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($AdminCreds.Password)
    $AdminPassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr)
    $ComputerName = Get-Content env:computername

    Node localhost
    {
        LocalConfigurationManager
        {           
            ConfigurationMode   = 'ApplyOnly'
            RebootNodeIfNeeded  = $true
        }
        
        xScript DelayBeforeDNS
        {
            SetScript = {
                # Force a 30 second sleep
                Start-Sleep -seconds 30
            }

            GetScript =  
            {
                return @{ "Result" = "false" }
            }

            TestScript = 
            {
                return $false
            }
        }

        # ***** Add DNS and AD Features *****
        WindowsFeature DNS 
        { 
            Ensure    = "Present" 
            Name      = "DNS"		
            DependsOn = '[xScript]DelayBeforeDNS'
        }

        Script EnableDNSDiags
        {
            SetScript = { 
                Set-DnsServerDiagnostics -All $true
                Write-Verbose -Verbose "Enabling DNS client diagnostics" 
            }
            GetScript   = { @{} }
            TestScript  = { $false }
            DependsOn   = "[WindowsFeature]DNS"
        }

        WindowsFeature DnsTools
        {
            Ensure      = "Present"
            Name        = "RSAT-DNS-Server"
            DependsOn   = "[WindowsFeature]DNS"
        }

        DnsServerAddress SetDNS 
        { 
            Address         = '127.0.0.1' 
            InterfaceAlias  = $InterfaceAlias
            AddressFamily   = 'IPv4'
            DependsOn       = "[WindowsFeature]DNS"
        }

        WindowsFeature ADDSInstall 
        { 
            Ensure      = "Present" 
            Name        = "AD-Domain-Services"
            DependsOn   = "[WindowsFeature]DNS" 
        } 

        WindowsFeature ADDSTools
        {
            Ensure      = "Present"
            Name        = "RSAT-ADDS-Tools"
            DependsOn   = "[WindowsFeature]ADDSInstall"
        }

        WindowsFeature ADAdminCenter
        {
            Ensure      = "Present"
            Name        = "RSAT-AD-AdminCenter"
            DependsOn   = "[WindowsFeature]ADDSTools"
        }
        

        PendingReboot RebootOnSignalFromADAdminCenter
        {
            Name        = 'RebootOnSignalFromADAdminCenter'
            DependsOn   = "[WindowsFeature]ADAdminCenter"
        }
    }
}

function Get-NetBIOSName {
    [OutputType([string])]
    param(
        [string]$DomainFQDN
    )

    if ($DomainFQDN.Contains('.')) {
        $length = $DomainFQDN.IndexOf('.')
        if ( $length -ge 16) {
            $length = 15
        }
        return $DomainFQDN.Substring(0, $length)
    }
    else {
        if ($DomainFQDN.Length -gt 15) {
            return $DomainFQDN.Substring(0, 15)
        }
        else {
            return $DomainFQDN
        }
    }
}