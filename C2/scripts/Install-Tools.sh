## Script is currently choking on a kernel mismatch and pending reboot

#!/bin/bash

# Check if user is root
if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root" 1>&2
    exit 1
fi

# apt packages
# apt-get update -y && apt-get full-upgrade -y
apt-get update -y
apt-get install python3 -y
apt-get install virtualenv -y
apt-get install python3-distutils python3-virtualenv libssl-dev libffi-dev python-dev-is-python3 build-essential smbclient libpcap-dev apt-transport-https -y
apt-get install vim-nox htop ncat rlwrap golang jq feroxbuster silversearcher-ag testssl.sh nmap masscan proxychains4 -y
apt-get install python3.11-venv -y
apt-get install onesixtyone snmp-mibs-downloader -y
apt-get install net-tools
apt-get install zsh
# Install latest metasploit
gem install bundler
apt-get install metasploit-framework -y

# remove outdated packages
apt-get autoremove -y

# Install neo4j
echo "deb http://httpredir.debian.org/debian stretch-backports main" | sudo tee -a /etc/apt/sources.list.d/stretch-backports.list
wget -O - https://debian.neo4j.com/neotechnology.gpg.key | sudo apt-key add -
echo 'deb https://debian.neo4j.com stable 4.0' > /etc/apt/sources.list.d/neo4j.list
apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 0E98404D386FA1D9 648ACFD622F3D138
apt update
apt install neo4j -y
systemctl stop neo4j
echo "dbms.default_listen_address=10.0.0.8" >> /etc/neo4j/neo4j.conf
# don't open the console dave. especially not during bootstrap
systemctl start neo4j

# update snmp.conf
sed -e '/mibs/ s/^#*/#/' -i /etc/snmp/snmp.conf

# Repos
[[ ! -d /opt/testssl.sh ]] && git clone --depth 1 https://github.com/drwetter/testssl.sh.git /opt/testssl.sh
[[ ! -d /opt/Responder ]] && git clone https://github.com/lgandx/Responder.git /opt/Responder
[[ ! -d /opt/impacket ]] && git clone https://github.com/fortra/impacket.git /opt/impacket
[[ ! -d /opt/BloodHound.py ]] && git clone https://github.com/fox-it/BloodHound.py.git /opt/BloodHound.py
[[ ! -d /opt/Certipy ]] && git clone https://github.com/ly4k/Certipy.git /opt/Certipy
[[ ! -d /opt/Coercer ]] && git clone https://github.com/p0dalirius/Coercer.git /opt/Coercer
[[ ! -d /opt/mitm6 ]] && git clone https://github.com/dirkjanm/mitm6.git /opt/mitm6
[[ ! -d /opt/PCredz ]] && git clone https://github.com/lgandx/PCredz.git /opt/PCredz
[[ ! -d /opt/certsync ]] && git clone https://github.com/zblurx/certsync.git /opt/certsync
[[ ! -d /opt/pyLAPS ]] && git clone https://github.com/p0dalirius/pyLAPS.git /opt/pyLAPS
[[ ! -d /opt/PlumHound ]] && git clone https://github.com/PlumHound/PlumHound.git /opt/PlumHound
[[ ! -d /opt/CrackMapExec ]] && git clone https://github.com/byt3bl33d3r/CrackMapExec.git /opt/CrackMapExec

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
    fi
}

install_with_virtualenv Responder
install_with_virtualenv impacket
install_with_virtualenv BloodHound.py
install_with_virtualenv PlumHound
install_with_virtualenv Certipy
install_with_virtualenv Coercer
install_with_virtualenv mitm6

install_pipx() {
    # check if pipx is already installed
    PIPX_EXISTS=$(which pipx)
    if [ -z "$PIPX_EXISTS" ]; then
        # Get the Python 3 version
        python_version_output=$(python3 --version 2>&1)
        python_version=$(echo "$python_version_output" | awk '{print $2}' | cut -d '.' -f 1,2)

        if [ "$python_version" == "3.10" ] || [ "$python_version" == "3.11" ] || [ "$python_version" == "3.12" ]; then
            python3 -m pip install pipx --break-system-packages || python3 -m pip install pipx
        elseapt update

}

install_pipx