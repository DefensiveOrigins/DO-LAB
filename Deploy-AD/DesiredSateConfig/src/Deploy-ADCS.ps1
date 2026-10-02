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

    # Domain-qualify the builder credential (e.g. DOAZLAB\dolabbuilder). AdminCreds.UserName is
    # unqualified, which on a member server resolves to the LOCAL admin; the Enterprise CA install
    # and template publish/ACL need the DOMAIN account (the forest builder / Enterprise Admin).
    [String] $DomainNetbiosName = (Get-NetBIOSName -DomainFQDN $DomainFQDN)
    [System.Management.Automation.PSCredential]$DomainCreds = New-Object System.Management.Automation.PSCredential ("${DomainNetbiosName}\$($AdminCreds.UserName)", $AdminCreds.Password)

    Node localhost
    {
        LocalConfigurationManager
        {           
            ConfigurationMode   = 'ApplyOnly'
            RebootNodeIfNeeded  = $true
        }

        # ***** Install ADCS *****
        # ADCS now runs on a member server (SRV01), not the DC. A member server's SYSTEM account
        # lacks the Enterprise-Admin rights needed to install an Enterprise Root CA and to
        # publish/ACL templates in the AD Configuration partition, so the resource runs under
        # AdminCreds (the forest builder, an Enterprise Admin). See HARDENING.md for the
        # least-privilege alternative (pre-delegating Public Key Services rights to the SRV01
        # computer account so this can run as SYSTEM instead).
        xScript InstallADCS
        {
            PsDscRunAsCredential = $DomainCreds
            SetScript = {

                [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

                Get-WindowsFeature -Name AD-Certificate | Install-WindowsFeature
                Add-WindowsFeature Adcs-Cert-Authority -IncludeManagementTools
                # A member server lacks the ActiveDirectory PowerShell module a DC has by
                # default; the ADCSTemplate module (New-ADCSTemplate / Set-ADCSTemplateACL)
                # #requires it, so install RSAT-AD-PowerShell before the template steps.
                Add-WindowsFeature RSAT-AD-PowerShell -IncludeManagementTools
                # Idempotency guard: Install-AdcsCertificationAuthority throws
                # CertificationAuthoritySetupException ("The Certification Authority is already installed")
                # when the CA role is already configured. Because TestScript always returns $false, this
                # SetScript re-runs on any redeploy; without this guard a re-run aborts here before the
                # template / ESC steps. Swallow only the already-installed case.
                try {
                    Install-AdcsCertificationAuthority -CAType EnterpriseRootCA -Force -ErrorAction Stop
                } catch {
                    if ("$_" -notmatch 'already installed') { throw }
                    Write-Host "ADCS CA already installed; skipping configuration."
                }

                Add-WindowsFeature ADCS-Enroll-Web-Pol -IncludeManagementTools 
                Add-WindowsFeature Adcs-Enroll-Web-Svc -IncludeManagementTools 
                Add-WindowsFeature ADCS-Web-Enrollment -IncludeManagementTools 
                Add-WindowsFeature ADCS-Device-Enrollment -IncludeManagementTools 
                Add-WindowsFeature ADCS-Online-Cert -IncludeManagementTools 
                
                #Install-AdcsEnrollmentPolicyWebService -Force
                #Install-AdcsEnrollmentWebService -Force
                #Install-AdcsNetworkDeviceEnrollmentService -Force
                #Install-AdcsOnlineresponder -Force
		# Add web enrollment
                Install-AdcsWebEnrollment -Force

                # Bind web enrollment to HTTPS on 443 as well. Without a 443 listener the
                # inbound SYN is dropped, so Certipy's web-enrollment check (certipy find)
                # hangs on its HTTPS probe and reports a timeout even though HTTP (80)
                # enrollment works. A self-signed cert is sufficient for the lab.
                Import-Module WebAdministration
                $webCert = New-SelfSignedCertificate -DnsName 'SRV01.doazlab.com' -CertStoreLocation 'Cert:\LocalMachine\My'
                New-WebBinding -Name 'Default Web Site' -Protocol https -Port 443 -IPAddress '*' -ErrorAction SilentlyContinue
                New-Item -Path "IIS:\SslBindings\0.0.0.0!443" -Value $webCert -ErrorAction SilentlyContinue


                #Add Default templates
                Add-CATemplate "ClientAuth" -Force
                Add-CATemplate "CodeSigning" -Force 
                Add-CATemplate "Workstation" -Force
                Add-CATemplate "SmartcardUser" -Force
                Add-CATemplate "ExchangeUser" -Force
                Add-CATemplate "EnrollmentAgent" -Force

                #Install module to manage import/export of templates.
                # Bootstrap the NuGet provider + trust PSGallery BEFORE the first Install-Module. On a fresh,
                # non-interactive (Session 0) DSC run the first Install-Module has to silently auto-install the
                # NuGet provider; when that bootstrap does not complete, Install-Module returns "No match was
                # found ... module name 'ADCSTemplate'" and the whole ADCS config fails (and, with the CA
                # already installed, a redeploy cannot recover). Do it explicitly, with retries for transient
                # PSGallery hiccups.
                Get-PackageProvider -Name NuGet -ForceBootstrap -ErrorAction SilentlyContinue | Out-Null
                Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -ErrorAction SilentlyContinue | Out-Null
                if (Get-PSRepository -Name PSGallery -ErrorAction SilentlyContinue) {
                    Set-PSRepository -Name PSGallery -InstallationPolicy Trusted -ErrorAction SilentlyContinue
                }
                for ($i = 1; $i -le 5 -and -not (Get-Module ADCSTemplate -ListAvailable); $i++) {
                    try {
                        Install-Module ADCSTemplate -Force -Scope AllUsers -ErrorAction Stop
                    } catch {
                        Write-Host "Install-Module ADCSTemplate attempt $i failed: $_"
                        Start-Sleep -Seconds 15
                    }
                }
                Import-Module ADCSTemplate -Force -ErrorAction SilentlyContinue
                #Export-ADCSTemplate vuln_Template > vuln_template.json

                #Download DOLAB templates 
                $wc = new-object System.Net.WebClient
                $wc.DownloadFile('https://raw.githubusercontent.com/DefensiveOrigins/AC-Extras/refs/heads/main/ADCS/DOAZLab_Computer.json', 'C:\ProgramData\DOAZLab_Computer.json')
                $wc.DownloadFile('https://raw.githubusercontent.com/DefensiveOrigins/AC-Extras/refs/heads/main/ADCS/DOAZLab_User.json', 'C:\ProgramData\DOAZLab_User.json')

                #Import DOLAB templates
                New-ADCSTemplate -DisplayName DOAZLab_Computer -JSON (Get-Content C:\ProgramData\DOAZLab_Computer.json -Raw) -Publish
                New-ADCSTemplate -DisplayName DOAZLab_User -JSON (Get-Content C:\ProgramData\DOAZLab_User.json -Raw) -Publish

		# Set Enrollment Rights
  		Set-ADCSTemplateACL -DisplayName DOAZLab_Computer  -Enroll -Identity 'DOAZLab\Domain Computers'
                Set-ADCSTemplateACL -DisplayName DOAZLab_User  -Enroll -Identity 'DOAZLab\Domain Users'

                #ESC4 (L2012 ESC4 step): publish a benign template, then grant the low-privileged lab user
                # GenericAll over the template object. That write access is the ESC4 condition - the student
                # reconfigures the template into an ESC1 state (enrollee-supplies-subject + client-auth EKU)
                # with Certipy and enrolls. lablowpriv is created early by Add-DC3-Objects on the DC.
                New-ADCSTemplate -DisplayName DOAZLab_ESC4 -JSON (Get-Content C:\ProgramData\DOAZLab_User.json -Raw) -Publish -ErrorAction SilentlyContinue
                Set-ADCSTemplateACL -DisplayName DOAZLab_ESC4 -Enroll -Identity 'DOAZLab\Domain Users'
                try {
                    Import-Module ActiveDirectory -ErrorAction Stop
                    $confNC = (Get-ADRootDSE).configurationNamingContext
                    $tmplDN = "CN=DOAZLab_ESC4,CN=Certificate Templates,CN=Public Key Services,CN=Services,$confNC"
                    $sid = (Get-ADUser -Identity lablowpriv).SID
                    $acl = Get-Acl -Path "AD:$tmplDN"
                    $ace = New-Object System.DirectoryServices.ActiveDirectoryAccessRule($sid, 'GenericAll', 'Allow')
                    $acl.AddAccessRule($ace)
                    Set-Acl -Path "AD:$tmplDN" -AclObject $acl
                } catch { Write-Host "ESC4 template ACL grant failed: $_" }

                #ESC6
                certutil -config "SRV01.doazlab.com\doazlab-SRV01-CA" -setreg policy\Editflags +EDITF_ATTRIBUTESUBJECTALTNAME2

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