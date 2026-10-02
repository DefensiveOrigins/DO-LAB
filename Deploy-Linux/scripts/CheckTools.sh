
# Create Log File and Directory if it doesnt exist.
mkdir -p /etc/DOAZLAB && touch /etc/DOAZLAB/VersionLog

#### CHECK VERSIONS ######
echo "Time: $(date).---------------------------------" >> /etc/DOAZLAB/VersionLog
echo "Time: $(date). START VERSION CHECKS" >> /etc/DOAZLAB/VersionLog
echo "Time: $(date).---------------------------------" >> /etc/DOAZLAB/VersionLog
# System tools
{
    echo "Time: $(date). python3: $(python3 --version 2>&1)"
    echo "Time: $(date). virtualenv: $(virtualenv --version 2>&1)"
    echo "Time: $(date). nmap: $(nmap --version 2>&1 | head -n 1)"
    echo "Time: $(date). net-tools (ifconfig): $(ifconfig --version 2>&1 | head -n 1)"
    echo "Time: $(date). golang: $(go version 2>&1)"
    echo "Time: $(date). docker: $(docker --version 2>&1)"
    echo "Time: $(date). docker-compose: $(docker compose version 2>&1 | head -n 1)"
    echo "Time: $(date). jq: $(jq --version 2>&1)"
    echo "Time: $(date). masscan: $(masscan --version 2>&1 | head -n 2 | grep version)"
    echo "Time: $(date). proxychains4: $(proxychains4 --version 2>&1 | head -n 1)"
    echo "Time: $(date). vim-nox: $(vim --version 2>&1 | head -n 1)"
    echo "Time: $(date). htop: $(htop --version 2>&1 | head -n 1)"
    echo "Time: $(date). ncat: $(ncat --version 2>&1 | head -n 1)"
    echo "Time: $(date). rlwrap: $(rlwrap --version 2>&1 | head -n 1)"
    echo "Time: $(date). onesixtyone: $(onesixtyone 2>&1 | head -n 1)"
    echo "Time: $(date). snmp-mibs-downloader: $(apt-cache policy snmp-mibs-downloader | grep Installed)"
    echo "Time: $(date). zsh: $(zsh --version 2>&1)"
    echo "Time: $(date). bundler: $(bundler --version 2>&1)"
    echo "Time: $(date). rustc: $(rustc --version 2>&1)"
    echo "Time: $(date). cargo: $(cargo --version 2>&1)"
    echo "Time: $(date). testssl.sh: $(/opt/testssl.sh/testssl.sh --version 2>&1 | head -n 3|grep version)"
    echo "Time: $(date). silversearcher-ag: $(ag --version 2>&1 | head -n 1)"
    echo "Time: $(date). msfconsole: $(msfconsole --version 2>&1 | head -n 1)"
} >> /etc/DOAZLAB/VersionLog

# Go tools
{
    echo "Time: $(date). kerbrute: $([ -x "${HOME}/go/bin/kerbrute" ] && ${HOME}/go/bin/kerbrute version 2>&1 | head -n 9|grep Version)"
    echo "Time: $(date). httpx: $([ -x "${HOME}/go/bin/httpx" ] && ${HOME}/go/bin/httpx --version 2>&1 | head -n 12|grep Version)"
    echo "Time: $(date). dnsx: $([ -x "${HOME}/go/bin/dnsx" ] && ${HOME}/go/bin/dnsx --version 2>&1 | head -n 10|grep Version)"
    echo "Time: $(date). gobuster: $([ -x "${HOME}/go/bin/gobuster" ] && ${HOME}/go/bin/gobuster --version 2>&1 | head -n 1)"
    echo "Time: $(date). nuclei: $([ -x "${HOME}/go/bin/nuclei" ] && ${HOME}/go/bin/nuclei --version 2>&1 | head -n 1)"
} >> /etc/DOAZLAB/VersionLog


# Python virtualenv tools
report_venv_version() {
    REPO_NAME="$1"
    VENV_PATH="${HOME}/pyenv/${REPO_NAME}/bin/activate"
    if [ -f "$VENV_PATH" ]; then
        . "$VENV_PATH"
        echo "Time: $(date). ${REPO_NAME}: $(python3 -m pip show $REPO_NAME 2>/dev/null | grep Version | head -n 1)" >> /etc/DOAZLAB/VersionLog
        deactivate
    else
        echo "Time: $(date). ${REPO_NAME}: venv not found" >> /etc/DOAZLAB/VersionLog
    fi
}

# Python virtualenv tools
report_venv_version impacket
report_venv_version PlumHound
report_venv_version Coercer
report_venv_version mitm6
report_venv_version NetExec
report_venv_version ADExplorerSnapshot
report_venv_version bofhound

# Python versions special - Responder
REPO_NAME="Responder"
VENV_PATH="${HOME}/pyenv/${REPO_NAME}/bin/activate"
if [ -f "$VENV_PATH" ]; then
   . "$VENV_PATH"
   echo "Time: $(date). ${REPO_NAME}: $(python3 /opt/Responder/Responder.py --version 2>/dev/null | grep Responder)" >> /etc/DOAZLAB/VersionLog
   deactivate
else
   echo "Time: $(date). ${REPO_NAME}: venv not found" >> /etc/DOAZLAB/VersionLog
fi

# Python versions special - BloodHound.py
REPO_NAME="BloodHound.py"
VENV_PATH="${HOME}/pyenv/${REPO_NAME}/bin/activate"
if [ -f "$VENV_PATH" ]; then
   . "$VENV_PATH"
   echo "Time: $(date). ${REPO_NAME}: $(python3 /opt/BloodHound.py/bloodhound.py 2>&1 | grep INFO)" >> /etc/DOAZLAB/VersionLog
   deactivate
else
   echo "Time: $(date). ${REPO_NAME}: venv not found" >> /etc/DOAZLAB/VersionLog
fi

# Python versions special - Certipy
REPO_NAME="Certipy"
VENV_PATH="${HOME}/pyenv/${REPO_NAME}/bin/activate"
if [ -f "$VENV_PATH" ]; then
   . "$VENV_PATH"
   echo "Time: $(date). ${REPO_NAME}:  $(certipy -v 2>&1 | head -n 1)" >> /etc/DOAZLAB/VersionLog
   deactivate
else
   echo "Time: $(date). ${REPO_NAME}: venv not found" >> /etc/DOAZLAB/VersionLog
fi

# Python versions special - PetitPotam (no venv of its own; runs under the impacket venv)
REPO_NAME="PetitPotam"
VENV_PATH="${HOME}/pyenv/impacket/bin/activate"
if [ -f /opt/PetitPotam/PetitPotam.py ] && [ -f "$VENV_PATH" ]; then
   . "$VENV_PATH"
   echo "Time: $(date). ${REPO_NAME}: PetitPotam.py present; impacket $(python3 -m pip show impacket 2>/dev/null | grep Version | head -n 1)" >> /etc/DOAZLAB/VersionLog
   deactivate
else
   echo "Time: $(date). ${REPO_NAME}: not found (expected /opt/PetitPotam/PetitPotam.py + impacket venv)" >> /etc/DOAZLAB/VersionLog
fi


echo "Time: $(date).---------------------------------" >> /etc/DOAZLAB/VersionLog
echo "Time: $(date).END VERSION CHECKS" >> /etc/DOAZLAB/VersionLog
echo "Time: $(date).---------------------------------" >> /etc/DOAZLAB/VersionLog


cat /etc/DOAZLAB/VersionLog