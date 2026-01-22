# Author: Roberto Rodriguez @Cyb3rWard0g
# License: GPLv3
# References:
# https://github.com/Azure/azure-quickstart-templates/blob/master/sharepoint-adfs/dsc/ConfigureDCVM.ps1
configuration Create-AD {
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
            Ensure  = "Present" 
            Name    = "DNS"		
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
            DependsOn   = "[WindowsFeature]ADDSInstall"
        }
         
        # ****** Create AD Domain *********
        ADDomain CreateADForest 
        {
            DomainName                      = $DomainFQDN
            Credential                      = $DomainCreds
            SafemodeAdministratorPassword   = $DomainCreds
            DatabasePath                    = "C:\NTDS"
            LogPath                         = "C:\NTDS"
            SysvolPath                      = "C:\SYSVOL"
            DependsOn                       = "[DnsServerAddress]SetDNS", "[WindowsFeature]ADDSInstall"
        }

        PendingReboot RebootOnSignalFromCreateADForest
        {
            Name        = 'RebootOnSignalFromCreateADForest'
            DependsOn   = "[ADDomain]CreateADForest"
        }

        WaitForADDomain WaitForDCReady
        {
            DomainName              = $DomainFQDN
            WaitTimeout             = 300
            RestartCount            = 3
            Credential              = $DomainCreds
            WaitForValidCredentials = $true
            DependsOn               = "[PendingReboot]RebootOnSignalFromCreateADForest"
        }

        # ***** Create OUs *****
        xScript CreateOUs
        {
            SetScript = {
                # Verifying ADWS service is running
                $ServiceName = 'ADWS'
                $arrService = Get-Service -Name $ServiceName

                while ($arrService.Status -ne 'Running')
                {
                    Start-Service $ServiceName
                    Start-Sleep -seconds 5
                    $arrService.Refresh()
                }

                $DomainName1,$DomainName2 = ($using:domainFQDN).split('.')

                $ParentPath = "DC=$DomainName1,DC=$DomainName2"
                $OUS = @(("Workstations","Workstations in the domain"),("Servers","Servers in the domain"),("LogCollectors","Servers collecting event logs"),("DomainUsers","Users in the domain"))

                foreach($OU in $OUS)
                {
                    #Check if exists, if it does skip
                    [string] $Path = "OU=$($OU[0]),$ParentPath"
                    if(![adsi]::Exists("LDAP://$Path"))
                    {
                        New-ADOrganizationalUnit -Name $OU[0] -Path $ParentPath `
                            -Description $OU[1] `
                            -ProtectedFromAccidentalDeletion $false -PassThru
                    }
                }
            }
            GetScript =  
            {
                # This block must return a hashtable. The hashtable must only contain one key Result and the value must be of type String.
                return @{ "Result" = "false" }
            }
            TestScript = 
            {
                # If it returns $false, the SetScript block will run. If it returns $true, the SetScript block will not run.
                return $false
            }
            DependsOn = "[WaitForADDomain]WaitForDCReady"
        }

        # ***** Create Domain Users *****
        xScript CreateDomainUsers
        {
            SetScript = {
                # Verifying ADWS service is running
                $ServiceName = 'ADWS'
                $arrService = Get-Service -Name $ServiceName

                while ($arrService.Status -ne 'Running')
                {
                    Start-Service $ServiceName
                    Start-Sleep -seconds 5
                    $arrService.Refresh()
                }

                $DomainName = $using:domainFQDN
                $DomainName1,$DomainName2 = $DomainName.split('.')
                $ADServer = $using:ComputerName+"."+$DomainName

                $NewDomainUsers = $using:DomainUsers
                
                foreach ($DomainUser in $NewDomainUsers)
                {
                    $UserPrincipalName = $DomainUser.SamAccountName + "@" + $DomainName
                    $DisplayName = $DomainUser.LastName + " " + $DomainUser.FirstName
                    $OUPath = "OU="+$DomainUser.UserContainer+",DC=$DomainName1,DC=$DomainName2"
                    $SamAccountName = $DomainUser.SamAccountName
                    $ServiceName = $DomainUser.FirstName

                    $UserExists = Get-ADUser -LDAPFilter "(sAMAccountName=$SamAccountName)"

                    if ($UserExists -eq $Null)
                    {
                        write-host "Creating user $UserPrincipalName .."
                        New-ADUser -Name $DisplayName `
                        -DisplayName $DisplayName `
                        -GivenName $DomainUser.FirstName `
                        -Surname $DomainUser.LastName `
                        -Department $DomainUser.Department `
                        -Title $DomainUser.JobTitle `
                        -UserPrincipalName $UserPrincipalName `
                        -SamAccountName $DomainUser.SamAccountName `
                        -Path $OUPath `
                        -AccountPassword (ConvertTo-SecureString $DomainUser.Password -AsPlainText -force) `
                        -Enabled $true `
                        -PasswordNeverExpires $true `
                        -Server $ADServer

                        if($DomainUser.Identity -Like "Domain Admins")
                        {
                            $DomainAdminUser = $DomainUser.SamAccountName
                            $Groups = @('domain admins','schema admins','enterprise admins')
                            $Groups | ForEach-Object{
                                $members = Get-ADGroupMember -Identity $_ -Recursive | Select-Object -ExpandProperty Name
                                if ($members -contains $DomainAdminUser)
                                {
                                    Write-Host "$DomainAdminUser exists in $_ "
                                }
                                else {
                                    Add-ADGroupMember -Identity $_ -Members $DomainAdminUser
                                }
                            }
                        }
                        if($DomainUser.JobTitle -Like "Service Account")
                        {
                            setspn -a $ServiceName/$DomainName $DomainName1\$SamAccountName
                        }
                    }
                }
            }
            GetScript =  
            {
                # This block must return a hashtable. The hashtable must only contain one key Result and the value must be of type String.
                return @{ "Result" = "false" }
            }
            TestScript = 
            {
                # If it returns $false, the SetScript block will run. If it returns $true, the SetScript block will not run.
                return $false
            }
            DependsOn = "[xScript]CreateOUs"
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