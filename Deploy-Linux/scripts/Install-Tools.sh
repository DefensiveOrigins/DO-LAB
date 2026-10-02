## Script is currently choking on a kernel mismatch and pending reboot

#!/bin/bash

# Create Log File and Directory if it doesnt exist.
mkdir -p /etc/DOAZLAB && touch /etc/DOAZLAB/DOAZLABLog

# Check if user is root
if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root" 1>&2
    exit 1
fi

echo "Time: $(date). Kickoff Tool Installs" >> /etc/DOAZLAB/DOAZLABLog
# apt packages
echo "Time: $(date). ---APT PACAKGES---" >> /etc/DOAZLAB/DOAZLABLog

# apt-get update -y && apt-get full-upgrade -y
apt-get update -y
echo "Time: $(date). ---APT: python3 Install ---" >> /etc/DOAZLAB/DOAZLABLog
apt-get install python3 -y 
echo "Time: $(date). ---APT: virtualenv Install ---" >> /etc/DOAZLAB/DOAZLABLog
apt-get install virtualenv -y
echo "Time: $(date). ---APT: python3 tools, dev, build-essentials, smbclient Install ---" >> /etc/DOAZLAB/DOAZLABLog
apt-get install python3-virtualenv libssl-dev libffi-dev python-dev-is-python3 build-essential smbclient libpcap-dev apt-transport-https ldap-utils -y
echo "Time: $(date). ---APT: proxychains4 ---" >> /etc/DOAZLAB/DOAZLABLog
apt-get install proxychains4 -y
echo "Time: $(date). ---APT: nmap Install ---" >> /etc/DOAZLAB/DOAZLABLog
apt-get install nmap -y
echo "Time: $(date). ---APT: net-tools Install ---" >> /etc/DOAZLAB/DOAZLABLog
apt-get install net-tools -y
echo "Time: $(date). ---APT: golang  Install ---" >> /etc/DOAZLAB/DOAZLABLog
apt-get install golang -y
echo "Time: $(date). ---APT: golang-go  Install ---" >> /etc/DOAZLAB/DOAZLABLog
apt-get install golang-go -y
# TODO: pretty sure some of these are not getting installed. Need to investigate
echo "Time: $(date). ---APT: vim-nox htop ncat rlwrap  Install ---" >> /etc/DOAZLAB/DOAZLABLog
apt-get install vim-nox htop ncat rlwrap -y
echo "Time: $(date). ---APT: jq feroxbuster silversearcher-ag testssl.sh nmap masscan proxychains4  Install ---" >> /etc/DOAZLAB/DOAZLABLog
apt-get install jq silversearcher-ag testssl.sh nmap masscan  -y
echo "Time: $(date). ---APT: onesixtyone snmp-mibs-downloader Install ---" >> /etc/DOAZLAB/DOAZLABLog
apt-get install onesixtyone snmp-mibs-downloader -y
echo "Time: $(date). ---APT: net-tool, zsh Install ---" >> /etc/DOAZLAB/DOAZLABLog
apt-get install zsh -y
echo "Time: $(date). ---APT: DOCKER Install ---" >> /etc/DOAZLAB/DOAZLABLog
apt install docker-compose-v2 -y

# Packages not available 8/4/26
# apt install feroxbuster -y
# apt-get install python3.11-venv -y
# apt-get install metasploit-framework -y

# Install Bundler
echo "Time: $(date). ---GEM: bundler Install ---" >> /etc/DOAZLAB/DOAZLABLog
gem install bundler

# Install metasploit
echo "Time: $(date). ---Install Metasploit ---" >> /etc/DOAZLAB/DOAZLABLog

#Check if signature file exists, if it does, prior install was attempted and should be removed prior to reinstall.

if command -v msfconsole >/dev/null 2>&1; then
    echo "Metasploit is already installed."
    echo "Time: $(date). ---Meteasploit - EAlready Installed" >> /etc/DOAZLAB/DOAZLABLog

else
    if [ -f /usr/share/keyrings/metasploit-framework.gpg ]; then
         echo "Time: $(date). ---Meteasploit - Evidence of prior install attempt - cleanup gpg" >> /etc/DOAZLAB/DOAZLABLog
         mv /usr/share/keyrings/metasploit-framework.gpg /usr/share/keyrings/metasploit-framework.gpg.old
    else 
         echo "Time: $(date). ---Meteasploit - Appears to be first install" >> /etc/DOAZLAB/DOAZLABLog
    fi 
    echo "Time: $(date). ---Meteasploit - Installing" >> /etc/DOAZLAB/DOAZLABLog
    curl https://raw.githubusercontent.com/rapid7/metasploit-omnibus/master/config/templates/metasploit-framework-wrappers/msfupdate.erb > msfinstall && chmod 755 msfinstall && ./msfinstall
echo "Time: $(date). ---Meteasploit - End install" >> /etc/DOAZLAB/DOAZLABLog
fi

# remove outdated packages
echo "Time: $(date). ---apt auto-remove ---" >> /etc/DOAZLAB/DOAZLABLog
apt-get autoremove -y

# Install neo4j
# echo "deb http://httpredir.debian.org/debian stretch-backports main" | sudo tee -a /etc/apt/sources.list.d/stretch-backports.list
# wget -O - https://debian.neo4j.com/neotechnology.gpg.key | sudo apt-key add -
# echo 'deb https://debian.neo4j.com stable 4.0' > /etc/apt/sources.list.d/neo4j.list
# apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 0E98404D386FA1D9 648ACFD622F3D138
# apt update
# apt install neo4j -y
# systemctl stop neo4j
# echo "dbms.default_listen_address=10.0.0.8" >> /etc/neo4j/neo4j.conf
# # don't open the console dave. especially not during bootstrap
# systemctl start neo4j

# update snmp.conf
echo "Time: $(date). Update SNMP ---" >> /etc/DOAZLAB/DOAZLABLog

sed -e '/mibs/ s/^#*/#/' -i /etc/snmp/snmp.conf

# Install Rust (NetExec Requirement)
echo "Time: $(date).---Rust Install ---" >> /etc/DOAZLAB/DOAZLABLog
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
source "$HOME/.cargo/env"
rustc --version && cargo --version

# Repos
echo "Time: $(date).---GIT CLONES ---" >> /etc/DOAZLAB/DOAZLABLog

[[ ! -d /opt/testssl.sh ]] && git clone --depth 1 https://github.com/drwetter/testssl.sh.git /opt/testssl.sh
[[ ! -d /opt/Responder ]] && git clone https://github.com/lgandx/Responder.git /opt/Responder
[[ ! -d /opt/impacket ]] && git clone https://github.com/fortra/impacket.git /opt/impacket
[[ ! -d /opt/BloodHound.py ]] && git clone https://github.com/fox-it/BloodHound.py.git /opt/BloodHound.py
[[ ! -d /opt/Certipy ]] && git clone https://github.com/DefensiveOrigins/Certipyv5.git /opt/Certipy
[[ ! -d /opt/Coercer ]] && git clone https://github.com/p0dalirius/Coercer.git /opt/Coercer
# PetitPotam has no venv of its own; it depends only on impacket and runs under the impacket pyenv.
[[ ! -d /opt/PetitPotam ]] && git clone https://github.com/topotam/PetitPotam.git /opt/PetitPotam
[[ ! -d /opt/mitm6 ]] && git clone https://github.com/dirkjanm/mitm6.git /opt/mitm6
[[ ! -d /opt/PCredz ]] && git clone https://github.com/lgandx/PCredz.git /opt/PCredz
[[ ! -d /opt/certsync ]] && git clone https://github.com/zblurx/certsync.git /opt/certsync
[[ ! -d /opt/pyLAPS ]] && git clone https://github.com/p0dalirius/pyLAPS.git /opt/pyLAPS
[[ ! -d /opt/PlumHound ]] && git clone https://github.com/PlumHound/PlumHound.git /opt/PlumHound
[[ ! -d /opt/CrackMapExec ]] && git clone https://github.com/byt3bl33d3r/CrackMapExec.git /opt/CrackMapExec
[[ ! -d /opt/NetExec ]] && git clone https://github.com/Pennyw0rth/NetExec.git /opt/NetExec
[[ ! -d /opt/ADExplorerSnapshot ]] && git clone https://github.com/c3c/ADExplorerSnapshot.git /opt/ADExplorerSnapshot
[[ ! -d /opt/bofhound ]] && git clone https://github.com/coffeegist/bofhound.git /opt/bofhound
# SCCM attack tooling (L2017 SCCM lab)
[[ ! -d /opt/sccmhunter ]] && git clone https://github.com/DefensiveOrigins/sccmhunter.git /opt/sccmhunter
# GPO abuse tooling (L2019 GPO-Abuse lab)
[[ ! -d /opt/pyGPOAbuse ]] && git clone https://github.com/Hackndo/pyGPOAbuse.git /opt/pyGPOAbuse

cat << 'EOF' >> "${HOME}/.screenrc"
termcapinfo * ti@:te@
caption always
caption string "%{kw}%-w%{wr}%n %t%{-}%+w"
startup_message off
defscrollback 1000000
EOF

# setup GOPATH. Lots of confusion about GOPATH and GOMODULES
# this will need rectified for bash or the implant / nux build needs shell swapped to zsh
# see https://zchee.github.io/golang-wiki/GOPATH/ and https://maelvls.dev/go111module-everywhere/ for more info
# TL:DR
# GOPATH is still supported even though it has been replaced by Go modules and is technically deprecated since Go 1.16, BUT, you can still use GOPATH to specify where you want your go binaries installed.
echo "Time: $(date).---Go Setup and Configurations ---" >> /etc/DOAZLAB/DOAZLABLog

wget https://go.dev/dl/go1.21.4.linux-amd64.tar.gz
tar -C ~/ -xzf go1.21.4.linux-amd64.tar.gz

[[ ! -d "${HOME}/go" ]] && mkdir "${HOME}/go"
if [[ -z "${GOPATH}" ]]; then
cat << 'EOF' >> "${HOME}/.zshrc"

# Add ~/go/bin to path
[[ ":$PATH:" != *":${HOME}/go/bin:"* ]] && export PATH="${PATH}:${HOME}/go/bin"
# Set GOPATH
if [[ -z "${GOPATH}" ]]; then export GOPATH="${HOME}/go"; fi
EOF
fi

[[ ":$PATH:" != *":${HOME}/go/bin:"* ]] && export PATH="${PATH}:${HOME}/go/bin"
# Set GOPATH
if [[ -z "${GOPATH}" ]]; then export GOPATH="${HOME}/go"; fi

# Install your favorite Go binaries
# GO111MODULE=on go install github.com/mr-pmillz/gorecon/v2@latest Use the private version from our Gitlab
GO111MODULE=on go install github.com/ropnop/kerbrute@latest
GO111MODULE=on go install -v github.com/projectdiscovery/httpx/cmd/httpx@latest
GO111MODULE=on go install -v github.com/projectdiscovery/dnsx/cmd/dnsx@latest
GO111MODULE=on go install -v github.com/OJ/gobuster/v3@latest
GO111MODULE=on go install -v github.com/projectdiscovery/nuclei/v3/cmd/nuclei@latest
[[ -f "${HOME}/go/bin/nuclei" ]] && nuclei -ut || echo "nuclei not in ${HOME}/go/bin/"

# create virtualenv dir.
[[ ! -d "${HOME}/pyenv" ]] && mkdir "${HOME}/pyenv"

# ignore shellcheck warnings for source commands
# shellcheck source=/dev/null

install_with_virtualenv() {
    REPO_NAME="$1"
    PYENV="${HOME}/pyenv"
    echo "Time: $(date).---InstallWithVirtualEnv: ${REPO_NAME} ---" >> /etc/DOAZLAB/DOAZLABLog
    if [ -d "/opt/${REPO_NAME}" ]; then
        cd "/opt/${REPO_NAME}" || exit 1
        virtualenv -p python3 "${PYENV}/${REPO_NAME}"
        . "${PYENV}/${REPO_NAME}/bin/activate"
        python3 -m pip install -U wheel setuptools
        # first, ensure that requirements.txt deps are installed.
        [[ -f requirements.txt ]] && python3 -m pip install -r requirements.txt
        # python3 setup.py install is deprecated in versions >= python3.9.X
        # python3 -m pip install . will handle the setup.py file for you.
        [[ -f setup.py || -f pyproject.toml ]] && python3 -m pip install .
        deactivate
        cd - &>/dev/null || exit 1
    else
        echo -e "${REPO_NAME} does not exist."
        echo "Time: $(date)---InstallWithVirtualEnv: ${REPO_NAME} does not exist." >> /etc/DOAZLAB/DOAZLABLog
    fi
}

echo "Time: $(date).---InstallWithVirtualEnvs ---" >> /etc/DOAZLAB/DOAZLABLog
install_with_virtualenv Responder
install_with_virtualenv impacket
install_with_virtualenv BloodHound.py
install_with_virtualenv PlumHound
install_with_virtualenv Certipy
install_with_virtualenv Coercer
install_with_virtualenv mitm6
install_with_virtualenv NetExec
install_with_virtualenv ADExplorerSnapshot
install_with_virtualenv bofhound
install_with_virtualenv sccmhunter
install_with_virtualenv pyGPOAbuse

install_pipx() {
    # check if pipx is already installed
    PIPX_EXISTS=$(which pipx)
    if [ -z "$PIPX_EXISTS" ]; then
        echo "Time: $(date).---Pipx not found" >> /etc/DOAZLAB/DOAZLABLog
        # Get the Python 3 version
        python_version_output=$(python3 --version 2>&1)
        python_version=$(echo "$python_version_output" | awk '{print $2}' | cut -d '.' -f 1,2)
        if [ "$python_version" == "3.10" ] || [ "$python_version" == "3.11" ] || [ "$python_version" == "3.12" ]; then
            echo "Time: $(date).---Installing Pipx installing" >> /etc/DOAZLAB/DOAZLABLog
            python3 -m pip install pipx --break-system-packages || python3 -m pip install pipx
        else
            echo "Time: $(date).---Pipx Version for py 3.11, 3.10/11/12 OK" >> /etc/DOAZLAB/DOAZLABLog
        fi
    else 
        echo "Time: $(date).---Pipx Found" >> /etc/DOAZLAB/DOAZLABLog
    fi
}

echo "Time: $(date).---Install Pipx" >> /etc/DOAZLAB/DOAZLABLog
install_pipx


echo "Time: $(date).---Kickoff Version Check.  Check file /etc/DOAZLAB/VersionLog" >> /etc/DOAZLAB/DOAZLABLog
/bin/bash /etc/DOAZLAB/CheckTools.sh