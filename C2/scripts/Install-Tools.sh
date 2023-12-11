#!/bin/bash


# Run as root, please, it's just easier that way
# this runs in a crontab, so don't run as sudo.  If you ever need to run manually, call sudo first
# sudo -s

echo "Time: $(date). Starting Installing Tools" >> /etc/DOAZLAB/DOAZLABLog

cd /etc/DOAZLAB


# Install python3.9
echo "Time: $(date). -- 10 --  Python3.9" >> /etc/DOAZLAB/DOAZLABLog
mkdir /opt/install-logs/
apt install python3.9 -y | tee -a /opt/install-logs/python3.9.log
apt update |tee -a /opt/install-logs/apt-update-after-python.log


# Use virtual environments to containerize python-based tooling
echo "Time: $(date). -- 20 --  Python venv" >> /etc/DOAZLAB/DOAZLABLog
apt install python3.9-dev python3.9-venv -y | tee -a /opt/install-logs/python-devs.log


# pip installer for 3.9
echo "Time: $(date). -- 30 --  Python pip" >> /etc/DOAZLAB/DOAZLABLog
curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py
python3.9 get-pip.py | tee -a /opt/install-logs/pip.log


# install a pre-req for a cffi package req
# broke here, everything after is sus
echo "Time: $(date). -- 40 --  libffi-dev" >> /etc/DOAZLAB/DOAZLABLog
apt install libffi-dev -y | tee -a /opt/install-logs/libffi.log


# Add nmap whois zip
echo "Time: $(date). -- 50 --  nmap net-tools whois zip" >> /etc/DOAZLAB/DOAZLABLog
apt install nmap net-tools whois zip -y


# First up: impacket
# clone it, cd to it, add a venv container, activate, add wheel, install tools, deactivate
echo "Time: $(date). -- 60 -- impacket" >> /etc/DOAZLAB/DOAZLABLog
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
echo "Time: $(date). -- 70 -- CME" >> /etc/DOAZLAB/DOAZLABLog
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
echo "Time: $(date). -- 80 -- PlumHound" >> /etc/DOAZLAB/DOAZLABLog
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
echo "Time: $(date). -- 90 -- BloodHound.py" >> /etc/DOAZLAB/DOAZLABLog
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
echo "Time: $(date). -- 100 -- BruteLoops.py" >> /etc/DOAZLAB/DOAZLABLog

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
echo "Time: $(date). -- 110 -- bl-bfg" >> /etc/DOAZLAB/DOAZLABLog
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
echo "Time: $(date). -- 120 -- neo4j" >> /etc/DOAZLAB/DOAZLABLog
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
echo "Time: $(date). -- 130 -- metasploit" >> /etc/DOAZLAB/DOAZLABLog
apt install -y build-essential zlib1g zlib1g-dev libpq-dev libpcap-dev libsqlite3-dev ruby ruby-dev
mkdir /opt/apps /opt/apps/msf
cd /opt/apps/msf
curl https://raw.githubusercontent.com/rapid7/metasploit-omnibus/master/config/templates/metasploit-framework-wrappers/msfupdate.erb > msfinstall
chmod 755 msfinstall
./msfinstall |tee -a msf-install.log


# silenttrinity
echo "Time: $(date). -- 140 -- silenttrinity" >> /etc/DOAZLAB/DOAZLABLog
cd /opt/
git clone https://github.com/DefensiveOrigins/SILENTTRINITY.git
cd SILENTTRINITY/
python3.9 -m venv st-env
source st-env/bin/activate
python3.9 -m pip install wheel
python3.9 -m pip install -r requirements.txt
deactivate


# john the password ripper
echo "Time: $(date). -- 150 -- john" >> /etc/DOAZLAB/DOAZLABLog
mkdir -p ~/src
apt -y install git build-essential libssl-dev zlib1g-dev
apt -y install yasm pkg-config libgmp-dev libpcap-dev libbz2-dev
cd ~/src
git clone https://github.com/openwall/john -b bleeding-jumbo john
cd ~/src/john/src
./configure && make -s clean && make -sj4


# snag the hashes artifact archive
echo "Time: $(date). -- 160 -- hashes" >> /etc/DOAZLAB/DOAZLABLog
wget https://github.com/DefensiveOrigins/DO-LAB/raw/main/C2/artifacts/hashes.zip -O /opt/hashes.zip
cd /opt/
unzip hashes.zip
rm hashes.zip


echo "Time: $(date). Finished Installing Tools" >> /etc/DOAZLAB/DOAZLABLog
