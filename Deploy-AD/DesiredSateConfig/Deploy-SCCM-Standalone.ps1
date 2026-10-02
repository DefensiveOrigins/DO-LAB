<#
Deploy-SCCM-Standalone.ps1  -  manual, interactive launcher for the DOAZLab SCCM primary-site install.

SCCM is intentionally NOT installed by the automatic ARM/DSC lab deploy. This script is how you add
the SCCM primary site to an already-deployed lab, on demand.

HOW TO RUN
  1. RDP to the site server SRV01.
  2. Log on as an account that is a member of Schema Admins AND Domain Admins. The documented lab
     admin DOAZLab\DOAdmin (password DOLabAdmin1!) qualifies; so does the forest builder dolabbuilder.
  3. Open PowerShell "as administrator" (elevated).
  4. Run this script:  powershell -ExecutionPolicy Bypass -File .\Deploy-SCCM-Standalone.ps1

The script runs the install in your interactive session, so there is no scheduled task and no stored
credential. The heavy lifting lives in Install-SCCM.ps1 (which resolves its run-as identity at runtime
via [WindowsIdentity]::GetCurrent, so it becomes SQL sysadmin / SCCM Full Admin as whoever you are).
Install-SCCM.ps1 is idempotent, so re-running after an interruption resumes rather than restarts.

Full build (SQL 2022 + ADK + ConfigMgr primary site) runs 30-60+ minutes. Progress is logged to
C:\SCCMLab\deploy-sccm.log; success is marked by C:\SCCMLab\INSTALL-COMPLETE.flag.
#>
[CmdletBinding()]
param(
    # Path to the installer engine. Defaults to Install-SCCM.ps1 next to this script; if absent, the
    # script downloads it (see -InstallerUrl).
    [string]$InstallerPath,

    # Force a fresh download of the installer engine even if a local copy exists.
    [switch]$DownloadInstaller,

    [string]$InstallerUrl = 'https://raw.githubusercontent.com/DefensiveOrigins/DO-LAB/main/Deploy-AD/DesiredSateConfig/Install-SCCM.ps1',

    # Skip the elevation / account-rights preflight (not recommended).
    [switch]$SkipChecks
)

$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

function Fail($m){ Write-Host "[X] $m" -ForegroundColor Red; exit 1 }
function Ok($m){   Write-Host "[+] $m" -ForegroundColor Green }
function Info($m){ Write-Host "[*] $m" }

# --- Preflight -------------------------------------------------------------
if (-not $SkipChecks) {
    # 1. Elevated? SQL / ADK / ConfigMgr setup all require it.
    $id = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($id)
    if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        Fail "Not elevated. Re-launch PowerShell as administrator and run this again."
    }
    Ok "Elevated PowerShell."

    # 2. Domain account with the rights the install needs. Schema extend (extadsch) needs Schema Admins;
    #    the System Management container + ACL needs Domain Admins (which also makes you local admin on
    #    SRV01). Check the live logon token, which is what actually governs the session's rights.
    if ($id.Name -notmatch '\\') { Fail "Current identity '$($id.Name)' is not a domain account. Log on as DOAZLab\DOAdmin." }
    Info "Running as $($id.Name)."
    $token = & whoami /groups
    foreach ($need in 'Schema Admins','Domain Admins') {
        if ($token -match ('\\' + [regex]::Escape($need) + '\b')) {
            Ok "Member of $need."
        } else {
            Fail "$($id.Name) is not a member of '$need' in this session. Log on as DOAZLab\DOAdmin (or dolabbuilder). If the account was only just added to the group, log off and back on so the token refreshes."
        }
    }
}

# --- Locate the installer engine ------------------------------------------
if (-not $InstallerPath) { $InstallerPath = Join-Path $PSScriptRoot 'Install-SCCM.ps1' }
if ($DownloadInstaller -or -not (Test-Path $InstallerPath)) {
    $dst = 'C:\SCCMLab\Install-SCCM.ps1'
    New-Item -ItemType Directory -Force -Path (Split-Path $dst) | Out-Null
    Info "Fetching installer: $InstallerUrl"
    Invoke-WebRequest -Uri $InstallerUrl -OutFile $dst -UseBasicParsing
    $InstallerPath = $dst
}
Ok "Installer engine: $InstallerPath"

# --- Run in this interactive session (no scheduled task, no stored credential) --
Info "Starting SCCM install. This runs 30-60+ minutes (SQL 2022 + ADK + ConfigMgr primary site)."
Info "Live progress: Get-Content C:\SCCMLab\deploy-sccm.log -Wait"
& $InstallerPath

if (Test-Path 'C:\SCCMLab\INSTALL-COMPLETE.flag') {
    Ok "SCCM install complete. Site server SRV01, site code DOZ. NAA svc_sccmnaa is configured."
} else {
    Fail "Install-SCCM.ps1 returned without writing the completion flag. Review C:\SCCMLab\deploy-sccm.log, fix the failing step, and re-run this script (the installer is idempotent)."
}
