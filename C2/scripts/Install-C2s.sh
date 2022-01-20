#!/bin/bash


# This script is used for building a tooled up Debian install
# Includes some apt installs, some git clones and pip
# Script available for wide distribution
# Run as root, please, it's just easier that way
sudo -s

# housekeeping
apt update
apt upgrade -y


# Use virtual environments to containerize python-based tooling
apt install python3.8-venv -y


# Add nmap whois zip
apt install nmap whois zip -y


# Add john the rippah
mkdir /opt/john
apt update
apt -y install john john-data |tee -a /opt/john/install.log
john --device=0 --test=0 |tee -a /opt/john/test.log


# I use /opt/ to house tools
cd /opt/


# First up: impacket
# clone it, cd to it, add a venv container, activate, add wheel, install tools, deactivate

git clone https://github.com/SecureAuthCorp/impacket.git
cd impacket
python3 -m venv imp-env
source imp-env/bin/activate
python3 -m pip install wheel
python3 -m pip install .
deactivate
cd /opt/


# Next up: CrackMapExec
# clone it, cd to it, add a venv container, activate, add wheel, install tools, deactivate
cd /opt/
git clone https://github.com/DefensiveOrigins/APT22Things.git
mv APT22Things CrackMap
cd CrackMap
python3 -m venv cme-venv
source cme-venv/bin/activate
python3 -m pip install wheel
python3 -m pip install -r requirements.txt
python3 cme
deactivate
cd /opt/


# PlumHound
# clone it, cd to it, add a venv container, activate, add wheel, install tools, deactivate

cd /opt/ 
git clone https://github.com/PlumHound/PlumHound.git
cd PlumHound
python3 -m venv ph-venv
source ph-venv/bin/activate
python3 -m pip install wheel
python3 -m pip install -r requirements.txt
deactivate
cd /opt/


# BloodHound.py
# clone it, cd to it, add a venv container, activate, add wheel, install tools, deactivate

cd /opt/
git clone https://github.com/fox-it/BloodHound.py.git
cd BloodHound.py
python3 -m venv bh-env
source bh-env/bin/activate
python3 -m pip install wheel
python3 setup.py install
deactivate
cd /opt/


# BruteLoops
# clone it, cd to it, add a venv container, activate, add wheel, install tools, deactivate

cd /opt/
git clone https://github.com/arch4ngel/BruteLoops.git
cd BruteLoops
python3 -m venv bl-env
source bl-env/bin/activate
python3 -m pip install wheel
python3 -m pip install -r requirements.txt
deactivate
cd /opt/


# neo4j install
# this may shank all the things
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
# ./neo4j console
systemctl start neo4j


# metasploit. 
sudo -s
apt install -y build-essential zlib1g zlib1g-dev libpq-dev libpcap-dev libsqlite3-dev ruby ruby-dev
mkdir /opt/apps /opt/apps/msf
cd /opt/apps/msf
git clone https://github.com/rapid7/metasploit-framework.git
cd metasploit-framework/
sudo gem install bundler
bundle install


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
