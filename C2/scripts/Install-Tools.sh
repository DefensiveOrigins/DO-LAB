#!/bin/bash


# Run as root, please, it's just easier that way
# this runs in a crontab, so don't run as sudo.  If you ever need to run manually, call sudo first
# sudo -s

echo "Time: $(date). Starting Installing Tools" >> /etc/DOAZLAB/DOAZLABLog

cd /etc/DOAZLAB
mkdir /etc/DOAZLAB/install-logs/


# Install python3.10
echo "Time: $(date). -- 10 --  python3.10" >> /etc/DOAZLAB/DOAZLABLog

apt install python3.10 -y | tee -a /etc/DOAZLAB/install-logs/python3.10.log
apt update |tee -a /etc/DOAZLAB/install-logs/apt-update-after-python.log


# Use virtual environments to containerize python-based tooling
echo "Time: $(date). -- 20 --  Python venv" >> /etc/DOAZLAB/DOAZLABLog
apt install python3.10-dev python3.10-venv -y | tee -a /etc/DOAZLAB/install-logs/020-python-devs.log


# pip installer for 3.9
echo "Time: $(date). -- 30 --  Python pip" >> /etc/DOAZLAB/DOAZLABLog
curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py
python3.10 get-pip.py | tee -a /etc/DOAZLAB/install-logs/030-pip.log


# install a pre-req for a cffi package req
# broke here, everything after is sus
echo "Time: $(date). -- 40 --  libffi-dev" >> /etc/DOAZLAB/DOAZLABLog
apt install libffi-dev -y | tee -a /etc/DOAZLAB/install-logs/040-libffi.log


# Add nmap whois zip
echo "Time: $(date). -- 50 --  nmap net-tools whois zip" >> /etc/DOAZLAB/DOAZLABLog
apt install nmap net-tools whois zip -y | tee -a /etc/DOAZLAB/install-logs/050-apt.log


# First up: impacket
# clone it, cd to it, add a venv container, activate, add wheel, install tools, deactivate
echo "Time: $(date). -- 60 --  impacket" >> /etc/DOAZLAB/DOAZLABLog
cd /opt/
git clone https://github.com/SecureAuthCorp/impacket.git | tee -a /etc/DOAZLAB/install-logs/060-impacket.log
cd impacket
python3.10 -m venv imp-env | tee -a /etc/DOAZLAB/install-logs/060-impacket.log
source imp-env/bin/activate
python3.10 -m pip install wheel | tee -a /etc/DOAZLAB/install-logs/060-impacket.log
python3.10 -m pip install -r requirements.txt | tee -a /etc/DOAZLAB/install-logs/060-impacket.log
python3.10 -m pip install . | tee -a /etc/DOAZLAB/install-logs/060-impacket.log
deactivate
cd /opt/


# Next up: CrackMapExec
# clone it, cd to it, add a venv container, activate, add wheel, install tools, deactivate
echo "Time: $(date). -- 70 --  CME" >> /etc/DOAZLAB/DOAZLABLog
cd /opt/
git clone https://github.com/DefensiveOrigins/APT22Things.git | tee -a /etc/DOAZLAB/install-logs/070-CME.log
mv APT22Things CrackMap
cd CrackMap
python3.10 -m venv cme-venv
source cme-venv/bin/activate
python3.10 -m pip install wheel | tee -a /etc/DOAZLAB/install-logs/070-CME.log
python3.10 -m pip install -r requirements.txt | tee -a /etc/DOAZLAB/install-logs/070-CME.log
python3.10 cme | tee -a /etc/DOAZLAB/install-logs/070-CME.log
deactivate
cd /opt/


# PlumHound
# clone it, cd to it, add a venv container, activate, add wheel, install tools, deactivate
echo "Time: $(date). -- 80 --  PlumHound" >> /etc/DOAZLAB/DOAZLABLog
cd /opt/ 
git clone https://github.com/PlumHound/PlumHound.git | tee -a /etc/DOAZLAB/install-logs/080-PH.log
cd PlumHound
python3.10 -m venv ph-venv | tee -a /etc/DOAZLAB/install-logs/080-PH.log
source ph-venv/bin/activate | tee -a /etc/DOAZLAB/install-logs/080-PH.log
python3.10 -m pip install wheel | tee -a /etc/DOAZLAB/install-logs/080-PH.log
python3.10 -m pip install -r requirements.txt | tee -a /etc/DOAZLAB/install-logs/080-PH.log
python3.10 PlumHound.py | tee -a /etc/DOAZLAB/install-logs/080-PH.log
deactivate
cd /opt/


# BloodHound.py
# clone it, cd to it, add a venv container, activate, add wheel, install tools, deactivate
echo "Time: $(date). -- 90 --  BloodHound.py" >> /etc/DOAZLAB/DOAZLABLog
cd /opt/
git clone https://github.com/fox-it/BloodHound.py.git | tee -a /etc/DOAZLAB/install-logs/090-BH.log
cd BloodHound.py
python3.10 -m venv bh-env | tee -a /etc/DOAZLAB/install-logs/090-BH.log
source bh-env/bin/activate
python3.10 -m pip install wheel | tee -a /etc/DOAZLAB/install-logs/090-BH.log
python3.10 setup.py install | tee -a /etc/DOAZLAB/install-logs/090-BH.log
deactivate
cd /opt/


# BruteLoops
# clone it, cd to it, add a venv container, activate, add wheel, install tools, deactivate
echo "Time: $(date). -- 100 --  BruteLoops" >> /etc/DOAZLAB/DOAZLABLog

cd /opt/
git clone https://github.com/DefensiveOrigins/BruteLoops.git | tee -a /etc/DOAZLAB/install-logs/100-BruteLoops.log
cd BruteLoops
python3.10 -m venv bl-env | tee -a /etc/DOAZLAB/install-logs/100-BruteLoops.log
source bl-env/bin/activate
python3.10 -m pip install wheel | tee -a /etc/DOAZLAB/install-logs/100-BruteLoops.log
python3.10 -m pip install -r requirements.txt | tee -a /etc/DOAZLAB/install-logs/100-BruteLoops.log
deactivate
cd /opt/


# bl-bfg install (replace BruteLoops)
# couple additional steps here, but seemed ok in testing
echo "Time: $(date). -- 110 --  bl-bfg" >> /etc/DOAZLAB/DOAZLABLog
cd /opt/
git clone https://github.com/DefensiveOrigins/bl-bfg.git | tee -a /etc/DOAZLAB/install-logs/110-bl-bfg.log
cd bl-bfg
python3.10 -m venv bfg-env | tee -a /etc/DOAZLAB/install-logs/110-bl-bfg.log
source bfg-env/bin/activate
python3.10 -m pip install wheel | tee -a /etc/DOAZLAB/install-logs/110-bl-bfg.log
python3.10 -m pip install . | tee -a /etc/DOAZLAB/install-logs/110-bl-bfg.log
python3.10 setup.py install | tee -a /etc/DOAZLAB/install-logs/110-bl-bfg.log
python3.10 -m pip install IPython | tee -a /etc/DOAZLAB/install-logs/110-bl-bfg.log
deactivate
cd /opt/


# neo4j install
echo "Time: $(date). -- 120 --  neo4j" >> /etc/DOAZLAB/DOAZLABLog
echo "deb http://httpredir.debian.org/debian stretch-backports main" | sudo tee -a /etc/apt/sources.list.d/stretch-backports.list
wget -O - https://debian.neo4j.com/neotechnology.gpg.key | sudo apt-key add -
echo 'deb https://debian.neo4j.com stable 4.0' > /etc/apt/sources.list.d/neo4j.list
apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 0E98404D386FA1D9 648ACFD622F3D138 | tee -a /etc/DOAZLAB/install-logs/120-neo4j.log
apt update | tee -a /etc/DOAZLAB/install-logs/120-neo4j.log
apt install apt-transport-https -y | tee -a /etc/DOAZLAB/install-logs/120-neo4j.log
apt install neo4j -y | tee -a /etc/DOAZLAB/install-logs/120-neo4j.log
systemctl stop neo4j | tee -a /etc/DOAZLAB/install-logs/120-neo4j.log
cd /usr/bin
echo "dbms.default_listen_address=0.0.0.0" >> /etc/neo4j/neo4j.conf


# don't open the console dave. especially not during bootstrap
systemctl start neo4j | tee -a /etc/DOAZLAB/install-logs/120-neo4j.log


# metasploit. 
echo "Time: $(date). -- 130 --  metasploit" >> /etc/DOAZLAB/DOAZLABLog
apt install -y build-essential zlib1g zlib1g-dev libpq-dev libpcap-dev libsqlite3-dev ruby ruby-dev | tee -a /etc/DOAZLAB/install-logs/130-MSF.log
mkdir /opt/apps /opt/apps/msf
cd /opt/apps/msf
curl https://raw.githubusercontent.com/rapid7/metasploit-omnibus/master/config/templates/metasploit-framework-wrappers/msfupdate.erb > msfinstall
chmod 755 msfinstall
./msfinstall | tee -a /etc/DOAZLAB/install-logs/130-MSF.log


# silenttrinity
echo "Time: $(date). -- 140 --  silenttrinity" >> /etc/DOAZLAB/DOAZLABLog
cd /opt/
git clone https://github.com/DefensiveOrigins/SILENTTRINITY.git | tee -a /etc/DOAZLAB/install-logs/140-ST.log
cd SILENTTRINITY/
python3.10 -m venv st-env | tee -a /etc/DOAZLAB/install-logs/140-ST.log
source st-env/bin/activate | tee -a /etc/DOAZLAB/install-logs/140-ST.log
python3.10 -m pip install wheel | tee -a /etc/DOAZLAB/install-logs/140-ST.log
python3.10 -m pip install -r requirements.txt | tee -a /etc/DOAZLAB/install-logs/140-ST.log
deactivate


# john the password ripper
echo "Time: $(date). -- 150 --  john" >> /etc/DOAZLAB/DOAZLABLog
mkdir -p ~/src
apt -y install git build-essential libssl-dev zlib1g-dev | tee -a /etc/DOAZLAB/install-logs/150-John.log
apt -y install yasm pkg-config libgmp-dev libpcap-dev libbz2-dev  | tee -a /etc/DOAZLAB/install-logs/150-John.log
cd ~/src
git clone https://github.com/openwall/john -b bleeding-jumbo john  | tee -a /etc/DOAZLAB/install-logs/150-John.log
cd ~/src/john/src
./configure && make -s clean && make -sj4  | tee -a /etc/DOAZLAB/install-logs/150-John.log


# snag the hashes artifact archive
echo "Time: $(date). -- 160 --  hashes" >> /etc/DOAZLAB/DOAZLABLog
wget https://github.com/DefensiveOrigins/DO-LAB/raw/main/C2/artifacts/hashes.zip -O /opt/hashes.zip  | tee -a /etc/DOAZLAB/install-logs/160-hashes.log
cd /opt/
unzip hashes.zip  | tee -a /etc/DOAZLAB/install-logs/160-hashes.log
rm hashes.zip


echo "Time: $(date). Finished Installing Tools" >> /etc/DOAZLAB/DOAZLABLog
