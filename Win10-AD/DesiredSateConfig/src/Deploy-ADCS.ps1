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

                # from the UI, this is step 2 of post OS install (Add Roles)
                # step 1 is creds 
                # Server manager currently prompts to complete the install
                Add-WindowsFeature ADCS-Enroll-Web-Pol -IncludeManagementTools 
                Add-WindowsFeature Adcs-Enroll-Web-Svc -IncludeManagementTools 
                Add-WindowsFeature ADCS-Web-Enrollment -IncludeManagementTools 
                Add-WindowsFeature ADCS-Online-Cert -IncludeManagementTools 
                
                Install-AdcsEnrollmentPolicyWebService -Force
                Install-AdcsEnrollmentWebService -Force
                Install-AdcsOnlineresponder -Force
                Install-AdcsWebEnrollment -Force

                # Step 3 - add the CA name:
                # DC01.doazlab.com\doazlab-DC01-CA

                # Step 4 - set CES authentication type (Windows integrated)

                # Step 5 - specify CES service account
                # Use the built in application pool identity

                # Step 6 - authentication type for CEP (Windows integrated)

                # Step 7 - specify server authentication certificate 
                # Issued to DC01.doazlab.com

                # Step 8 - confirm everything

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
                $wc.DownloadFile('https://raw.githubusercontent.com/DefensiveOrigins/DO-LAB/main/Win10-AD/resources/ca_templates/DOAZLab_User.json', 'C:\ProgramData\DOAZLab_User.json')
                $wc.DownloadFile('https://raw.githubusercontent.com/DefensiveOrigins/DO-LAB/main/Win10-AD/resources/ca_templates/DOAZLab_Computer.json', 'C:\ProgramData\DOAZLab_Computer.json')
                $wc.DownloadFile('https://raw.githubusercontent.com/DefensiveOrigins/DO-LAB/main/Win10-AD/resources/ca_templates/DOAZLab_IPSec.json', 'C:\ProgramData\DOAZLab_IPSec.json')

                #Import DOLAB templates
                New-ADCSTemplate -DisplayName DOAZLab_User -JSON (Get-Content C:\ProgramData\DOAZLab_User.json -Raw) -Publish
                New-ADCSTemplate -DisplayName DOAZLab_Computer -JSON (Get-Content C:\ProgramData\DOAZLab_Computer.json -Raw) -Publish
                New-ADCSTemplate -DisplayName DOAZLab_IPSec -JSON (Get-Content C:\ProgramData\DOAZLab_IPSec.json -Raw) -Publish

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