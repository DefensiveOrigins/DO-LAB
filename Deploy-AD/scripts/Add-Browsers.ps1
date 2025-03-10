
#setup directory
$workdir = "C:\doazlab"
if (-Not (Test-Path -Path $workdir)) {
    New-Item -Path $workdir -ItemType Directory | Out-Null
}

## Add FF)
$workdir = "c:\doazlab\"
$source = "https://download.mozilla.org/?product=firefox-latest&os=win64&lang=en-US"
$destination = "$workdir\firefox.exe"
Invoke-WebRequest $source -OutFile $destination
Start-Process -FilePath "$workdir\firefox.exe" -ArgumentList "/S"
Start-Sleep -s 35

#setup directory
$workdir = "C:\doazlab"
if (-Not (Test-Path -Path $workdir)) {
    New-Item -Path $workdir -ItemType Directory | Out-Null
}

## Add Chrome
$workdir = "c:\doazlab\"
$source = "http://dl.google.com/chrome/install/375.126/chrome_installer.exe"
$destination = "$workdir\ChromeInstaller.exe"
Invoke-WebRequest $source -OutFile $destination
Start-Process -FilePath "$workdir\ChromeInstaller.exe" -ArgumentList " /silent /install"

