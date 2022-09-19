#!/bin/bash

# This script is used for building a tooled up Debian install
# Includes some apt installs, some git clonesand pip
# Script available for wide distribution


# Run as root, please, it's just easier that way
sudo -s


# housekeeping
apt update
apt upgrade -y


# Install python3.9
mkdir /opt/install-logs/
apt install python3.9 -y | tee -a /opt/install-logs/python3.9.log
apt update |tee -a /opt/install-logs/apt-update-after-python.log


# Use virtual environments to containerize python-based tooling
apt install python3.9-dev python3.9-venv -y | tee -a /opt/install-logs/python-devs.log


# pip installer for 3.9
curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py
python3.9 get-pip.py | tee -a /opt/install-logs/pip.log


# install a pre-req for a cffi package req
# broke here, everything after is sus
apt install libffi-dev -y | tee -a /opt/install-logs/libffi.log


# Add nmap whois zip
apt install nmap net-tools whois zip -y


# First up: impacket
# clone it, cd to it, add a venv container, activate, add wheel, install tools, deactivate

cd /opt/
git clone https://github.com/SecureAuthCorp/impacket.git
cd impacket
python3.9 -m venv imp-env
source imp-env/bin/activate
python3.9 -m pip install wheel
python3.9 -m pip install -r requirements.txt
python3.9 -m pip install .
deactivate
cd /opt/


# Next up: CrackMapExec
# clone it, cd to it, add a venv container, activate, add wheel, install tools, deactivate

cd /opt/
git clone https://github.com/DefensiveOrigins/APT22Things.git
mv APT22Things CrackMap
cd CrackMap
python3.9 -m venv cme-venv
source cme-venv/bin/activate
python3.9 -m pip install wheel
python3.9 -m pip install -r requirements.txt
python3.9 cme
deactivate
cd /opt/


# PlumHound
# clone it, cd to it, add a venv container, activate, add wheel, install tools, deactivate

cd /opt/ 
git clone https://github.com/PlumHound/PlumHound.git
cd PlumHound
python3.9 -m venv ph-venv
source ph-venv/bin/activate
python3.9 -m pip install wheel
python3.9 -m pip install -r requirements.txt
deactivate
cd /opt/


# BloodHound.py
# clone it, cd to it, add a venv container, activate, add wheel, install tools, deactivate

cd /opt/
git clone https://github.com/fox-it/BloodHound.py.git
cd BloodHound.py
python3.9 -m venv bh-env
source bh-env/bin/activate
python3.9 -m pip install wheel
python3.9 setup.py install
deactivate
cd /opt/


# BruteLoops
# clone it, cd to it, add a venv container, activate, add wheel, install tools, deactivate

cd /opt/
git clone https://github.com/DefensiveOrigins/BruteLoops.git
cd BruteLoops
python3.9 -m venv bl-env
source bl-env/bin/activate
python3.9 -m pip install wheel
python3.9 -m pip install -r requirements.txt
deactivate
cd /opt/


# bl-bfg install (replace BruteLoops)
# couple additional steps here, but seemed ok in testing

cd /opt/
git clone https://github.com/DefensiveOrigins/bl-bfg.git
cd bl-bfg
python3.9 -m venv bfg-env
source bfg-env/bin/activate
python3.9 -m pip install wheel
python3.9 -m pip install .
python3.9 setup.py install
python3.9 -m pip install IPython
deactivate
cd /opt/


# neo4j install
echo "deb http://httpredir.debian.org/debian stretch-backports main" | sudo tee -a /etc/apt/sources.list.d/stretch-backports.list
wget -O - https://debian.neo4j.com/neotechnology.gpg.key | sudo apt-key add -
echo 'deb https://debian.neo4j.com stable 4.0' > /etc/apt/sources.list.d/neo4j.list
apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 0E98404D386FA1D9 648ACFD622F3D138
apt update
apt install apt-transport-https -y 
apt install neo4j -y
systemctl stop neo4j
cd /usr/bin
echo "dbms.default_listen_address=0.0.0.0" >> /etc/neo4j/neo4j.conf


# don't open the console dave. especially not during bootstrap
systemctl start neo4j


# metasploit. 
sudo -s
apt install -y build-essential zlib1g zlib1g-dev libpq-dev libpcap-dev libsqlite3-dev ruby ruby-dev
mkdir /opt/apps /opt/apps/msf
cd /opt/apps/msf
curl https://raw.githubusercontent.com/rapid7/metasploit-omnibus/master/config/templates/metasploit-framework-wrappers/msfupdate.erb > msfinstall
chmod 755 msfinstall
./msfinstall |tee -a msf-install.log


# silenttrinity
cd /opt/
git clone https://github.com/DefensiveOrigins/SILENTTRINITY.git
cd SILENTTRINITY/
python3.9 -m venv st-env
source st-env/bin/activate
python3.9 -m pip install wheel
python3.9 -m pip install -r requirements.txt
deactivate


# john the password ripper
mkdir -p ~/src
apt -y install git build-essential libssl-dev zlib1g-dev
apt -y install yasm pkg-config libgmp-dev libpcap-dev libbz2-dev
cd ~/src
git clone https://github.com/openwall/john -b bleeding-jumbo john
cd ~/src/john/src
./configure && make -s clean && make -sj4


# snag the hashes artifact archive
wget https://github.com/DefensiveOrigins/DO-LAB/raw/main/C2/artifacts/hashes.zip -O /opt/hashes.zip
cd /opt/
unzip hashes.zip
rm hashes.zip
