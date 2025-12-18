[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$workdir = "C:\doazlab"
if (-Not (Test-Path -Path $workdir)) {
    New-Item -Path $workdir -ItemType Directory | Out-Null
}
mkdir c:\doaz
mkdir c:\doaz\gpo
cd c:\doaz\gpo
Invoke-WebRequest -URI https://github.com/dpcybuck/DO-LAB/raw/main/Deploy-AD/resources/doazlab_gpos.zip -Outfile doazlab_gpos.zip
Expand-Archive .\doazlab_gpos.zip
Remove-Item doazlab_gpos.zip
New-GPO "doaz-labsettings"
Import-GPO -BackupGpoName "doaz-labsettings" -TargetName "doaz-labsettings" -Path c:\doaz\gpo\doazlab_gpos
New-GPLink -Name "doaz-labsettings" -Target "dc=doazlab,dc=com" -LinkEnabled Yes
cd c:\doaz\gpo
Invoke-WebRequest -URI https://github.com/dpcybuck/DO-LAB/raw/main/Deploy-AD/resources/layout.xml -Outfile layout.xml
Copy-Item c:\doaz\gpo\layout.xml -Destination C:\SYSVOL\sysvol\doazlab.com\scripts\layout.xml
