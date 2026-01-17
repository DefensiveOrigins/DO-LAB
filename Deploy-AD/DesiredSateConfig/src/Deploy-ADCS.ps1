# Author: Roberto Rodriguez @Cyb3rWard0g
# License: GPLv3

configuration Deploy-ADCS {
    param 
    ( 
        [Parameter(Mandatory)]
        [String]$DomainFQDN,

        [Parameter(Mandatory)]
        [System.Management.Automation.PSCredential]$AdminCreds

    ) 
    Import-DscResource -ModuleName ActiveDirectoryDsc, NetworkingDsc, xPSDesiredStateConfiguration, ComputerManagementDsc
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

    Node localhost
    {
        LocalConfigurationManager
        {           
            ConfigurationMode   = 'ApplyOnly'
            RebootNodeIfNeeded  = $true
        }

        # ***** Install ADCS *****
        xScript InstallADCS
        {
            SetScript = {
                Get-WindowsFeature -Name AD-Certificate | Install-WindowsFeature
                Add-WindowsFeature Adcs-Cert-Authority -IncludeManagementTools
                Install-AdcsCertificationAuthority -CAType EnterpriseRootCA -Force

                Add-WindowsFeature ADCS-Enroll-Web-Pol -IncludeManagementTools 
                Add-WindowsFeature Adcs-Enroll-Web-Svc -IncludeManagementTools 
                Add-WindowsFeature ADCS-Web-Enrollment -IncludeManagementTools 
                Add-WindowsFeature ADCS-Device-Enrollment -IncludeManagementTools 
                Add-WindowsFeature ADCS-Online-Cert -IncludeManagementTools 
                
                #Install-AdcsEnrollmentPolicyWebService -Force
                #Install-AdcsEnrollmentWebService -Force
                #Install-AdcsNetworkDeviceEnrollmentService -Force
                #Install-AdcsOnlineresponder -Force
                Install-AdcsWebEnrollment -Force


                #Add Default templates
                Add-CATemplate "ClientAuth" -Force
                Add-CATemplate "CodeSigning" -Force 
                Add-CATemplate "Workstation" -Force
                Add-CATemplate "SmartcardUser" -Force
                Add-CATemplate "ExchangeUser" -Force
                Add-CATemplate "EnrollmentAgent" -Force

                #Install module to manage import/export of templates
                Install-Module ADCSTemplate -Force
                #Export-ADCSTemplate vuln_Template > vuln_template.json

                #Download DOLAB templates 
                $wc = new-object System.Net.WebClient
                $wc.DownloadFile('https://raw.githubusercontent.com/DefensiveOrigins/AC-Extras/refs/heads/main/ADCS/DOAZLab_Computer.json', 'C:\ProgramData\DOAZLab_Computer.json')
                $wc.DownloadFile('https://raw.githubusercontent.com/DefensiveOrigins/AC-Extras/refs/heads/main/ADCS/DOAZLab_User.json', 'C:\ProgramData\DOAZLab_User.json')
   

                #Import DOLAB templates
                New-ADCSTemplate -DisplayName DOAZLab_Computer -JSON (Get-Content C:\ProgramData\DOAZLab_Computer.json -Raw) -Publish
                New-ADCSTemplate -DisplayName DOAZLab_User -JSON (Get-Content C:\ProgramData\DOAZLab_User.json -Raw) -Publish
                Set-ADCSTemplateACL -DisplayName DOAZLab_Computer  -Enroll -Identity 'DOAZLab\Domain Computers'
                Set-ADCSTemplateACL -DisplayName DOAZLab_User  -Enroll -Identity 'DOAZLab\Domain Users'
                Set-ADCSTemplateACL -DisplayName DOAZLab_IPSec -Enroll -Identity 'DOAZLab\Domain Users'
                
                #ESC6 
                certutil -config "DC01.doazlab.com\doazlab-DC01-CA" -setreg policy\Editflags +EDITF_ATTRIBUTESUBJECTALTNAME2

                #Restart CertSrv
                Restart-Service -Name CertSvc

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
        }

        PendingReboot RebootOnSignalFromAADConnect
        {
            Name        = 'RebootOnSignalFromADCS'
            DependsOn   = "[xScript]InstallADCS"
        }

    }
}
