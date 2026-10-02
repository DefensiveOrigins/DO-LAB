# Enable machine certificate autoenrollment on this Domain Controller and enroll its
# Kerberos Authentication certificate, so LDAPS (Schannel) and Kerberos PKINIT work.
#
# ADCS runs on the member server SRV01, deployed AFTER the DC, so at DC-build time no CA
# existed. This runs on DC01 once the CA is up (ordered after SRV01-deployADCS). It runs as
# SYSTEM (Azure CustomScript extension); the DC's computer account holds Enroll/AutoEnroll
# rights on the KerberosAuthentication template that the Enterprise CA install auto-publishes.
# Idempotent: safe to re-run once the certificate is present.

$ErrorActionPreference = 'Continue'
$caConfig = 'SRV01.doazlab.com\doazlab-SRV01-CA'
$log = 'C:\Windows\Temp\autoenroll-status.txt'
"start $(Get-Date -Format o)" | Out-File $log -Encoding ascii

# 1. Trust the SRV01 Enterprise Root. Right after CA creation the root may not have propagated
#    to this DC via Group Policy yet, which fails enrollment with CERT_E_UNTRUSTEDROOT (0x800b0109).
#    Retrieve the CA cert directly and add it to the local machine Trusted Root store.
$caCer = "$env:TEMP\srv01ca.cer"
& certutil -config $caConfig -ca.cert $caCer *>&1 | Out-Null
if (Test-Path $caCer) {
    & certutil -addstore -f Root $caCer *>&1 | Out-Null
    "root trusted from $caConfig" | Out-File $log -Append -Encoding ascii
} else {
    "WARN: could not retrieve CA cert from $caConfig" | Out-File $log -Append -Encoding ascii
}

# 2. Enable machine autoenrollment policy (enroll + renew + update). Not set by default in this lab.
$key = 'HKLM:\Software\Policies\Microsoft\Cryptography\AutoEnrollment'
New-Item -Path $key -Force | Out-Null
Set-ItemProperty -Path $key -Name AEPolicy -Value 7 -Type DWord

# 3. Refresh computer policy and pulse autoenrollment (also distributes AD-published roots).
& gpupdate /target:computer /force *>&1 | Out-Null
& certutil -pulse *>&1 | Out-Null

# 4. Deterministic explicit enrollment as a fallback (idempotent; no-op if already present).
try {
    Import-Module PKI -ErrorAction SilentlyContinue
    $r = Get-Certificate -Template KerberosAuthentication -CertStoreLocation Cert:\LocalMachine\My -ErrorAction Stop
    "Get-Certificate status: $($r.Status)" | Out-File $log -Append -Encoding ascii
} catch {
    "Get-Certificate error: $($_.Exception.Message)" | Out-File $log -Append -Encoding ascii
}

# 5. Record the resulting DC certificate(s) issued by the SRV01 CA (for lab troubleshooting).
$have = Get-ChildItem Cert:\LocalMachine\My | Where-Object { $_.Issuer -like '*SRV01*' } |
    ForEach-Object { "HAVE: $($_.Subject) | EKU=$((($_.EnhancedKeyUsageList | ForEach-Object FriendlyName) -join ', '))" }
if (-not $have) { $have = 'HAVE: (no SRV01-issued cert in LocalMachine\My)' }
$have | Out-File $log -Append -Encoding ascii
"done" | Out-File $log -Append -Encoding ascii
