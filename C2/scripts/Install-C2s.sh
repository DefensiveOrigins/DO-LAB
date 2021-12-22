#!/bin/bash


# This script is used for building a tooled up Debian install
# Includes some apt installs, some git clones and pip
# Script available for wide distribution
# Run as root, please, it's just easier that way


# housekeeping
apt update
apt upgrade -y

# I use virtual environments to containerize python-based tooling
apt install python3-venv -y

# Add nmap 
apt install nmap whois -y

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