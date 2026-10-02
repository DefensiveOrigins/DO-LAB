# Install-SCCM.ps1  -  DOAZLab SCCM primary-site installer (plain script, idempotent, NO SSEI).
#
# Launched ASYNCHRONOUSLY by the Deploy-SCCM DSC bootstrap (Deploy-SCCM.ps1), which registers a
# scheduled task that runs this file as DOAZLAB\DOAdmin and returns immediately. A full SCCM build
# (SQL + ADK + ConfigMgr primary site) runs far longer than the Azure DSC extension's provisioning
# window, so it must NOT run inline in the DSC SetScript or ARM reports VMExtensionProvisioningTimeout.
#
# Media (deliberately NOT via the SSEI bootstrappers - as of 2026-09 the only SSEI builds Microsoft
# publishes are server-side deprecated and hard-stop with an invisible modal when run headless):
#   SQL 2022 Developer : official direct ISO on download.microsoft.com, mounted + setup /ConfigurationFile
#   ConfigMgr current  : WinRAR self-extractor from fwlink 2195628, extracted headless with -s2 -d
#
# The script is idempotent: every step checks whether it is already done and skips it, so the
# scheduled task can retry (e.g. after a reboot) without restarting from zero. On full success it
# drops a completion flag and unregisters its own scheduled task.
#
# Fixed lab: domain doazlab.com / NetBIOS DOAZLab, site server SRV01, site code DOZ.

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$ErrorActionPreference = 'Stop'

# ---- Lab-wide settings (kept in step with Add-DC3-Objects.ps1 and the courseware) ----
$SiteCode   = 'DOZ'
$SiteName   = 'DOAZLab Primary Site'
$SmsDir     = 'C:\Program Files\Microsoft Configuration Manager'
$SiteServer = "$($env:COMPUTERNAME).doazlab.com"    # SRV01.doazlab.com
# The site Full Admin / SQL sysadmin is whatever account this task actually runs as. The DSC
# bootstrap registers the task as the deploy's AdminCreds (the forest builder, e.g. dolabbuilder),
# NOT a separate "DOAdmin", so resolve it at runtime instead of hardcoding.
$SiteAdmin  = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name   # e.g. DOAZLab\dolabbuilder
$MachineAcct= "DOAZLab\$($env:COMPUTERNAME)`$"       # DOAZLab\SRV01$
$NaaUser    = 'DOAZLab\svc_sccmnaa'
$NaaPass    = 'Config#Mgr2026'                       # matches the domainUsers entry (must not contain the account name, per AD complexity)
$work       = 'C:\SCCMLab'
$flag       = "$work\INSTALL-COMPLETE.flag"
New-Item -ItemType Directory -Force -Path $work | Out-Null
function Log($m){ $line = "$(Get-Date -Format o)  $m"; $line | Out-File -Append "$work\deploy-sccm.log"; Write-Host $line }

if (Test-Path $flag) { Log 'INSTALL-COMPLETE.flag present; nothing to do.'; return }
Log '===== Install-SCCM.ps1 starting ====='

# Installer sources. Mirror these under AC-Extras and repoint if the public URLs ever drift.
$isoUrl   = 'https://download.microsoft.com/download/3/8/d/38de7036-2433-4207-8eae-06e247e17b25/SQLServer2022-x64-ENU-Dev.iso'  # SQL 2022 Developer ISO (verified official, ~1.08 GB)
$cmUrl    = 'https://go.microsoft.com/fwlink/?linkid=2195628'   # ConfigMgr current-branch baseline media (WinRAR self-extractor, ~1.2 GB)
$adkUrl   = 'https://go.microsoft.com/fwlink/?linkid=2289980'   # ADK for Win11 24H2
$adkPeUrl = 'https://go.microsoft.com/fwlink/?linkid=2289981'   # WinPE add-on

function Get-File($url, $dest) {
    if (Test-Path $dest) { Log "already present: $dest"; return }
    Log "downloading $url -> $dest"
    # Use WebClient (WinHTTP), NOT BITS. A BITS foreground transfer needs the owning user's
    # interactive logon session; under this non-interactive scheduled task (Session 0, running as
    # DOAdmin with no interactive session) Start-BitsTransfer creates a job that never completes
    # and throws - which stalled the first live run at the ADK download. WebClient has no such
    # dependency (it is also what the DSC SetScript uses to fetch this script).
    (New-Object System.Net.WebClient).DownloadFile($url, $dest)
}

# ================= 1. IIS + Windows features SCCM needs (ADCS already added Web-Server) ========
if ((Get-WindowsFeature Web-Server).Installed -and (Get-WindowsFeature BITS).Installed) {
    Log 'Windows/IIS prerequisite features already installed'
} else {
    Log 'Installing Windows/IIS prerequisite features'
    $features = @(
        'Web-Server','Web-Windows-Auth','Web-ASP-Net45','Web-Net-Ext45','Web-Metabase',
        'Web-WMI','Web-Static-Content','Web-Default-Doc','Web-Dir-Browsing','Web-Http-Errors',
        'Web-Http-Logging','Web-Request-Monitor','Web-Filtering','Web-ISAPI-Ext','Web-ISAPI-Filter',
        'Web-Mgmt-Console','Web-Mgmt-Compat','Web-Scripting-Tools',
        'BITS','BITS-IIS-Ext','RDC',
        'NET-Framework-Core','NET-Framework-45-Core','NET-Framework-45-ASPNET'   # NET-Framework-Core = .NET 3.5, a hard ConfigMgr prereq
    )
    Install-WindowsFeature -Name $features | Out-Null
    # WebDAV is not a Windows feature name; SCCM does not require it for HTTP MP/DP. Skipped.
}

# ================= 2. Windows ADK + WinPE add-on ==============================================
if (Test-Path 'C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit') {
    Log 'Windows ADK already installed'
} else {
    Log 'Installing Windows ADK + WinPE'
    $adkExe = "$work\adksetup.exe"; $adkPe = "$work\adkwinpesetup.exe"
    Get-File $adkUrl   $adkExe
    Get-File $adkPeUrl $adkPe
    Start-Process $adkExe -ArgumentList '/quiet /features OptionId.DeploymentTools OptionId.ImagingAndConfigurationDesigner /norestart' -Wait
    Start-Process $adkPe  -ArgumentList '/quiet /features OptionId.WindowsPreinstallationEnvironment /norestart' -Wait
}

# ================= 3. SQL Server 2022 (Developer) from the OFFICIAL DIRECT ISO (no SSEI) =======
if (Get-Service MSSQLSERVER -ErrorAction SilentlyContinue) {
    Log 'SQL Server (MSSQLSERVER) already installed'
} else {
    Log 'Installing SQL Server 2022 Developer from a mounted ISO'
    $iso = "$work\SQL2022-Dev.iso"
    Get-File $isoUrl $iso
    $mount = Mount-DiskImage -ImagePath $iso -PassThru
    try {
        $drive = ($mount | Get-Volume).DriveLetter
        $setup = "${drive}:\setup.exe"
        # NOTE: SQL + Agent run as NT AUTHORITY\SYSTEM here as a lab shortcut (local-only DB, no
        # Kerberos SPN needs). A production build uses dedicated low-priv service accounts.
        $sqlIni = @"
[OPTIONS]
ACTION="Install"
FEATURES=SQLENGINE
INSTANCENAME=MSSQLSERVER
SQLSYSADMINACCOUNTS="$SiteAdmin" "$MachineAcct"
SQLSVCACCOUNT="NT AUTHORITY\SYSTEM"
AGTSVCACCOUNT="NT AUTHORITY\SYSTEM"
SQLSVCSTARTUPTYPE="Automatic"
AGTSVCSTARTUPTYPE="Automatic"
TCPENABLED="1"
IACCEPTSQLSERVERLICENSETERMS="True"
SUPPRESSPRIVACYSTATEMENTNOTICE="True"
QUIET="True"
UPDATEENABLED="False"
"@
        $sqlIni | Out-File "$work\sql.ini" -Encoding ascii
        $p = Start-Process $setup -ArgumentList "/ConfigurationFile=$work\sql.ini" -Wait -PassThru
        if ($p.ExitCode -ne 0 -and $p.ExitCode -ne 3010) { throw "SQL setup exited $($p.ExitCode)" }
        Log "SQL setup exit code $($p.ExitCode)"
    } finally {
        Dismount-DiskImage -ImagePath $iso | Out-Null
    }
}

# ================= 3b. Cap SQL max server memory (sqlcmd is NOT installed with SQLENGINE only) =
# FEATURES=SQLENGINE does not ship sqlcmd.exe, so the cap is set through .NET SqlClient with the
# running account (DOAZLab\DOAdmin, a sysadmin) instead of shelling out to sqlcmd.
Log 'Capping SQL max server memory to 6144 MB'
try {
    $cn = New-Object System.Data.SqlClient.SqlConnection 'Server=localhost;Database=master;Integrated Security=True;TrustServerCertificate=True'
    $cn.Open()
    foreach ($q in @(
        "EXEC sp_configure 'show advanced options', 1; RECONFIGURE;",
        "EXEC sp_configure 'max server memory (MB)', 6144; RECONFIGURE;"
    )) { $cmd = $cn.CreateCommand(); $cmd.CommandText = $q; [void]$cmd.ExecuteNonQuery() }
    $cn.Close()
} catch { Log "memory cap failed (non-fatal): $_" }

# ================= 4. ConfigMgr baseline media (WinRAR self-extractor; no SSEI) ================
$cmSrc = "$work\CM"
function Find-CMSetup { Get-ChildItem $cmSrc -Recurse -Filter setup.exe -ErrorAction SilentlyContinue |
    Where-Object { $_.FullName -match '\\SMSSETUP\\BIN\\X64\\setup\.exe$' } |
    Select-Object -First 1 -ExpandProperty FullName }
$cmSetup = Find-CMSetup
if ($cmSetup) {
    Log "ConfigMgr media already extracted ($cmSetup)"
} else {
    Log 'Downloading + extracting ConfigMgr baseline media'
    $cmExe = "$work\MCM_Configmgr.exe"
    Get-File $cmUrl $cmExe
    New-Item -ItemType Directory -Force -Path $cmSrc | Out-Null
    # -s2 skips the WinRAR SFX confirmation dialog and auto-extracts with no interaction (verified
    # headless-safe under a scheduled task); -d sets the destination. The old /Auto switch is a
    # non-WinRAR argument that leaves the interactive Extract dialog up and hangs under SYSTEM.
    Start-Process $cmExe -ArgumentList "-s2","-d$cmSrc" -Wait
    $cmSetup = Find-CMSetup
}

# ================= 5. Extend AD schema + System Management container (runs as DOAdmin) =========
$domainNC = $null
try { Import-Module ActiveDirectory -ErrorAction Stop; $domainNC = (Get-ADRootDSE).defaultNamingContext } catch { Log "AD module load failed: $_" }

$extadsch = Get-ChildItem $cmSrc -Recurse -Filter extadsch.exe -ErrorAction SilentlyContinue | Select-Object -First 1 -ExpandProperty FullName
if ($extadsch) { Log 'Extending AD schema (extadsch.exe)'; Start-Process $extadsch -Wait } else { Log 'extadsch.exe not found; skipping schema extension' }

if ($domainNC) {
    $smDN = "CN=System Management,CN=System,$domainNC"
    if (-not (Get-ADObject -Filter "distinguishedName -eq '$smDN'" -ErrorAction SilentlyContinue)) {
        Log 'Creating the System Management container'
        New-ADObject -Name 'System Management' -Type 'container' -Path "CN=System,$domainNC"
    } else { Log 'System Management container already present' }
    Log 'Granting the site server computer account Full Control over the container (+ descendants)'
    # Use the AD: provider (from RSAT-AD-PowerShell, already installed) rather than dsacls.exe -
    # dsacls ships with the RSAT AD DS *tools*, which are NOT present on this member server, so
    # `& dsacls` is command-not-found and terminates the script before the site install.
    try {
        $compSid = (Get-ADComputer $env:COMPUTERNAME).SID
        $acl = Get-Acl -Path "AD:$smDN"
        $ace = New-Object System.DirectoryServices.ActiveDirectoryAccessRule(
            $compSid, 'GenericAll', 'Allow',
            [System.DirectoryServices.ActiveDirectorySecurityInheritance]::All)
        $acl.AddAccessRule($ace)
        Set-Acl -Path "AD:$smDN" -AclObject $acl
    } catch { Log "System Management container ACL grant failed: $_" }
}

# ================= 5b. ODBC Driver 18 for SQL Server (hard ConfigMgr SQL prereq) ==============
# ConfigMgr's SQL connectivity check builds a connection string that names "ODBC Driver 18 for
# SQL Server"; SQL setup only leaves Driver 17, so the check fails ("Invalid connection string
# attribute") until Driver 18 is present. The copy in the media (SMSSETUP\BIN\X64\msodbcsql.msi)
# is a 0-byte stub, so pull the real MSI from the fwlink ConfigMgr setup itself points at.
if (Get-OdbcDriver -Name 'ODBC Driver 18 for SQL Server' -ErrorAction SilentlyContinue) {
    Log 'ODBC Driver 18 for SQL Server already installed'
} else {
    Log 'Installing ODBC Driver 18 for SQL Server (fwlink 2220989)'
    $odbc = "$work\msodbcsql18.msi"
    Get-File 'https://go.microsoft.com/fwlink/?linkid=2220989' $odbc
    Start-Process msiexec.exe -ArgumentList '/i',$odbc,'/qn','IACCEPTMSODBCSQLLICENSETERMS=YES','ADDLOCAL=ALL' -Wait
}

# ================= 6. Install the ConfigMgr primary site (unattended) ==========================
if (Get-Service SMS_EXECUTIVE -ErrorAction SilentlyContinue) {
    Log 'ConfigMgr site already installed (SMS_EXECUTIVE present)'
} elseif ($cmSetup) {
    Log 'Running ConfigMgr unattended setup (this stage runs 30-60 min)'
    $prereqPath = "$work\CMPrereq"
    New-Item -ItemType Directory -Force -Path $prereqPath | Out-Null
    # PrerequisiteComp=0 => setup.exe downloads the redistributable prerequisites itself as part of
    # the unattended /script install. We do NOT pre-run the standalone setupdl.exe helper: it hangs
    # (0 CPU, no network, no window) in the non-interactive Session-0 scheduled-task context.
    $cmIni = @"
[Identification]
Action=InstallPrimarySite

[Options]
ProductID=EVAL
SiteCode=$SiteCode
SiteName=$SiteName
SMSInstallDir=$SmsDir
SDKServer=$SiteServer
RoleCommunicationProtocol=HTTPorHTTPS
ClientsUsePKICertificate=0
PrerequisiteComp=0
PrerequisitePath=$prereqPath
ManagementPoint=$SiteServer
ManagementPointProtocol=HTTP
DistributionPoint=$SiteServer
DistributionPointProtocol=HTTP
DistributionPointInstallIIS=0
AdminConsole=1
JoinCEIP=0

[SQLConfigOptions]
SQLServerName=$SiteServer
DatabaseName=CM_$SiteCode
SQLSSBPort=4022

[CloudConnectorOptions]
CloudConnector=0
CloudConnectorServer=$SiteServer
UseProxy=0

[SystemCenterOptions]

[HierarchyExpansionOption]
"@
    $cmIni | Out-File "$work\cm.ini" -Encoding ascii
    $p = Start-Process $cmSetup -ArgumentList "/script $work\cm.ini" -Wait -PassThru
    Log "ConfigMgr setup exit code $($p.ExitCode)"
}

# ================= 7. Post-install: NAA + boundary GROUP + client push =========================
# Validated live 2026-09-23. Notes: a boundary needs a boundary GROUP to assign clients/offer
# content; automatic client push needs AD System Discovery enabled + run so WS05 becomes a device
# first; the client-push account must already be a ConfigMgr account (so we reuse svc_sccmnaa,
# which for push to actually run must be local admin on the target clients - a lab-config item).
if (Get-Service SMS_EXECUTIVE -ErrorAction SilentlyContinue) {
    Log 'Configuring NAA + boundary group + AD discovery + client push'
    # The ConfigurationManager module ships with the admin console; SMS_ADMIN_UI_PATH (a machine
    # env var setup writes, e.g. ...\AdminConsole\bin\i386) is the reliable way to locate it.
    $uiPath = [Environment]::GetEnvironmentVariable('SMS_ADMIN_UI_PATH','Machine')
    $cmModule = if ($uiPath) { Join-Path (Split-Path $uiPath) 'ConfigurationManager.psd1' } else { $null }
    if ($cmModule) {
        Import-Module $cmModule
        if (-not (Get-PSDrive -Name $SiteCode -ErrorAction SilentlyContinue)) {
            New-PSDrive -Name $SiteCode -PSProvider CMSite -Root $SiteServer -Scope Global -ErrorAction SilentlyContinue | Out-Null
        }
        Push-Location "$($SiteCode):"
        try {
            # Network Access Account (the credential sccmhunter recovers from machine policy)
            if (-not (Get-CMAccount -UserName $NaaUser -ErrorAction SilentlyContinue)) {
                $sec = ConvertTo-SecureString $NaaPass -AsPlainText -Force
                New-CMAccount -UserName $NaaUser -Password $sec -SiteCode $SiteCode -ErrorAction SilentlyContinue
            }
            Set-CMSoftwareDistributionComponent -SiteCode $SiteCode -AddNetworkAccessAccountName $NaaUser -ErrorAction SilentlyContinue

            # Boundary + boundary GROUP (a boundary alone assigns nothing and offers no content)
            if (-not (Get-CMBoundary -BoundaryName 'DOAZLab' -ErrorAction SilentlyContinue)) {
                New-CMBoundary -Name 'DOAZLab' -Type IPRange -Value '192.168.2.1-192.168.2.254' -ErrorAction SilentlyContinue
            }
            if (-not (Get-CMBoundaryGroup -Name 'DOAZLab' -ErrorAction SilentlyContinue)) {
                New-CMBoundaryGroup -Name 'DOAZLab' -DefaultSiteCode $SiteCode -ErrorAction SilentlyContinue
            }
            Add-CMBoundaryToGroup -BoundaryName 'DOAZLab' -BoundaryGroupName 'DOAZLab' -ErrorAction SilentlyContinue
            Set-CMBoundaryGroup -Name 'DOAZLab' -AddSiteSystemServerName $SiteServer -ErrorAction SilentlyContinue

            # AD System Discovery must be enabled + run so WS05 becomes a device before client push
            $adDN = (Get-ADDomain).DistinguishedName
            Set-CMDiscoveryMethod -ActiveDirectorySystemDiscovery -SiteCode $SiteCode -Enabled $true `
                -AddActiveDirectoryContainer "LDAP://$adDN" -EnableRecursive $true -ErrorAction SilentlyContinue
            Invoke-CMSystemDiscovery -SiteCode $SiteCode -ErrorAction SilentlyContinue

            # Automatic site-wide client push. The push account must already be a ConfigMgr account,
            # so reuse svc_sccmnaa (created above). -AddAccount fails on an account that is not a CM
            # account (e.g. the run-as admin), which is why we do not use $SiteAdmin here.
            Set-CMClientPushInstallation -SiteCode $SiteCode -EnableAutomaticClientPushInstallation $true -ErrorAction SilentlyContinue
            Set-CMClientPushInstallation -SiteCode $SiteCode -AddAccount $NaaUser -ErrorAction SilentlyContinue
        } finally { Pop-Location }
    } else { Log 'ConfigurationManager.psd1 not found; skipping post-install config' }

    # Success: drop the completion flag and unregister the bootstrap task so it stops re-running.
    'complete' | Out-File $flag
    Log '===== Deploy-SCCM complete; completion flag written ====='
    Unregister-ScheduledTask -TaskName 'InstallSCCM' -Confirm:$false -ErrorAction SilentlyContinue
} else {
    Log 'ConfigMgr site NOT detected after setup; leaving completion flag unwritten so the task retries.'
}
