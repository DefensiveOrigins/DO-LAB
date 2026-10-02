# Hardening notes

Optional hardening changes that are intentionally NOT applied to the default build, recorded
so they can be turned on later without re-deriving the details. The default lab is a throwaway
attack range and deliberately ships weak credentials and open RDP/SSH, so most of these are only
relevant if you reuse parts of the build outside the classroom.

## ADCS CA install credential (SRV01)

The ADCS Certificate Authority runs on the member server **SRV01**, not the DC. Installing an
*Enterprise* Root CA and publishing/ACLing certificate templates writes to the AD Configuration
partition (`CN=Public Key Services,CN=Services,CN=Configuration,DC=doazlab,DC=com`), which by
default requires **Enterprise Admin** plus local admin. A member server's `SYSTEM` account does
not have those rights (a DC's `SYSTEM` did, which is why the old DC-hosted CA install needed no
credential).

### Current build — approach A (in use)

`Deploy-AD/DesiredSateConfig/src/Deploy-ADCS.ps1` runs the `xScript InstallADCS` resource under
`PsDscRunAsCredential = $DomainCreds`, where `$DomainCreds` is the domain-qualified builder
account (`DOAZLAB\dolabbuilder`, an Enterprise Admin — it is the account that created the forest).

- **Pro:** minimal change; no new secret is introduced (the same credential already ships in this
  DSC deployment's `protectedSettings` and already builds the whole forest and joins every host).
- **Residual risk:** the RunAs credential is stored (encrypted) in the pending MOF under
  `C:\Windows\System32\Configuration` on SRV01 and can be recovered by a SYSTEM-level compromise
  of that host. Because the lab teaches credential dumping, this makes a *SYSTEM-on-SRV01 →
  Enterprise Admin* path cleaner than it would otherwise be.

### Least-privilege alternative — approach B (not applied)

Remove the Enterprise Admin RunAs and instead pre-delegate only the rights the install needs to
the **SRV01 computer account** (or a dedicated scoped service account), then let the install run
as `SYSTEM` / that scoped account. No Enterprise Admin credential is ever materialized on SRV01.

Sketch (run on the DC, before `SRV01-deployADCS`, e.g. as an extra step in `Add-DC3-Objects` or a
new DC-side deployment):

1. Grant the SRV01 computer account (or scoped account) `GenericAll` (or the minimal
   create-child / write rights) on:
   - `CN=Public Key Services,CN=Services,CN=Configuration,DC=doazlab,DC=com`
   - `CN=Certification Authorities,CN=Public Key Services,...`
   - `CN=Enrollment Services,CN=Public Key Services,...`
   (e.g. via `dsacls` or the `ActiveDirectoryDsc`/`ADObjectPermissionEntry` resource.)
2. Ensure the account is a **local admin** on SRV01 (the computer account already is for its own
   role install; a scoped service account would need adding to local Administrators).
3. In `Deploy-ADCS.ps1`, drop `PsDscRunAsCredential = $DomainCreds` (run as SYSTEM) or set it to
   the scoped account instead of the Enterprise Admin.

Trade-off: more moving parts (the delegation must succeed before the CA install), in exchange for
removing the Enterprise-Admin-on-member-server exposure.
