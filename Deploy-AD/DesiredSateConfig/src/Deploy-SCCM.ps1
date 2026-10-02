# Deploy-SCCM.ps1  -  thin, ASYNC DSC bootstrap for the SCCM primary-site install.
#
# The heavy install logic lives in Install-SCCM.ps1 (a plain script). A full SCCM build
# (SQL + ADK + ConfigMgr primary site) runs far longer than the Azure DSC extension's provisioning
# window, so this SetScript does NOT run it inline (that produced ARM VMExtensionProvisioningTimeout).
# Instead it registers a scheduled task that runs Install-SCCM.ps1 as DOAZLAB\DOAdmin and returns
# immediately, letting the extension report success quickly while the install proceeds decoupled.
# Install-SCCM.ps1 is idempotent, so an -AtStartup retry after a reboot resumes rather than restarts,
# and it unregisters this task once it drops its completion flag.
#
# (Two WMF-5.1 constraints shaped this: a large inline SetScript mis-parses at DSC compile time, and
# $using: is unavailable, so the run-as credential is baked into the SetScript text at compile time.
# The lab admin password is already public in the deploy repo, so this is acceptable for the lab.)

configuration Deploy-SCCM {
    param
    (
        [Parameter(Mandatory)]
        [String]$DomainFQDN,

        [Parameter(Mandatory)]
        [System.Management.Automation.PSCredential]$AdminCreds
    )
    Import-DscResource -ModuleName xPSDesiredStateConfiguration

    [String] $DomainNetbiosName = (Get-NetBIOSName -DomainFQDN $DomainFQDN)
    $domUser    = "${DomainNetbiosName}\$($AdminCreds.UserName)"
    $domPass    = $AdminCreds.GetNetworkCredential().Password
    $installUrl = 'https://raw.githubusercontent.com/DefensiveOrigins/DO-LAB/main/Deploy-AD/DesiredSateConfig/Install-SCCM.ps1'

    # Build the SetScript with the run-as user/password baked in at compile time (no $using: on 5.1).
    $setScriptText = @"
        `$ErrorActionPreference = 'Stop'
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        New-Item -ItemType Directory -Force -Path 'C:\SCCMLab' | Out-Null
        Invoke-WebRequest -Uri '$installUrl' -OutFile 'C:\SCCMLab\Install-SCCM.ps1' -UseBasicParsing
        `$action  = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument '-NoProfile -ExecutionPolicy Bypass -File C:\SCCMLab\Install-SCCM.ps1'
        `$trigger = New-ScheduledTaskTrigger -AtStartup
        `$set     = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -ExecutionTimeLimit ([TimeSpan]::FromHours(4)) -RestartCount 3 -RestartInterval ([TimeSpan]::FromMinutes(5))
        Register-ScheduledTask -TaskName 'InstallSCCM' -Action `$action -Trigger `$trigger -Settings `$set -User '$domUser' -Password '$domPass' -RunLevel Highest -Force | Out-Null
        Start-ScheduledTask -TaskName 'InstallSCCM'
"@

    Node localhost
    {
        LocalConfigurationManager
        {
            ConfigurationMode  = 'ApplyOnly'
            RebootNodeIfNeeded = $true
        }

        # Bootstraps the installer as an independent scheduled task, then returns immediately.
        xScript BootstrapSCCM
        {
            SetScript  = [ScriptBlock]::Create($setScriptText)
            GetScript  = { return @{ "Result" = "false" } }
            TestScript = { return $false }
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
