# Author: Roberto Rodriguez @Cyb3rWard0g
# License: GPLv3
configuration Join-Domain {
    param 
    ( 
        [Parameter(Mandatory)]
        [String]$DomainFQDN,

        [Parameter(Mandatory)]
        [System.Management.Automation.PSCredential]$AdminCreds,

        [Parameter(Mandatory)]
        [String]$DCIPAddress,

        [Parameter(Mandatory)]
        [String]$JoinOU
    ) 
    
    Import-DscResource -ModuleName NetworkingDsc, ActiveDirectoryDsc, xPSDesiredStateConfiguration, ComputerManagementDsc
    
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

        DnsServerAddress SetDNS 
        { 
            Address         = $DCIPAddress
            InterfaceAlias  = $InterfaceAlias
            AddressFamily   = 'IPv4'
            DependsOn       = '[xScript]DelayBeforeDNS'
        }

        # ***** Join Domain *****
        WaitForADDomain WaitForDCReady
        {
            DomainName              = $DomainFQDN
            WaitTimeout             = 300
            RestartCount            = 3
            Credential              = $DomainCreds
            DependsOn               = "[DnsServerAddress]SetDNS"
        }

        Computer JoinDomain
        {
            Name          = $ComputerName 
            DomainName    = $DomainFQDN
            Credential    = $DomainCreds
            JoinOU        = $JoinOU
            DependsOn  = "[WaitForADDomain]WaitForDCReady"
        }

        PendingReboot RebootAfterJoiningDomain
        { 
            Name = "RebootServer"
            DependsOn = "[Computer]JoinDomain"
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