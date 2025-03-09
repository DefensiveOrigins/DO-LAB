#!/bin/bash


# Run as root, please, it's just easier that way
sudo -s


# Add folder, Download Scripts
mkdir /etc/DOAZLAB
cd /etc/DOAZLAB
wget https://raw.githubusercontent.com/DefensiveOrigins/DO-LAB/main/Deploy-Linux/scripts/Install-Tools.sh
wget https://raw.githubusercontent.com/DefensiveOrigins/DO-LAB/main/Deploy-Linux/scripts/RunAtReboot.sh
wget https://raw.githubusercontent.com/DefensiveOrigins/DO-LAB/main/Deploy-Linux/scripts/makekey.sh
chmod +x Install-Tools.sh
chmod +x RunAtReboot.sh
chmod +x makekey.sh

# Make SSH Key
bash makekey.sh

# Add Log
touch /etc/DOAZLAB/DOAZLABLog

## Add Crontab for RunAtReboot
echo "Time: $(date). Updating Crontab for RunAtReboot" >> /etc/DOAZLAB/DOAZLABLog
echo @reboot root /etc/DOAZLAB/RunAtReboot.sh >> /etc/crontab

#add RunOnceTrigger
echo "Time: $(date). Adding Tool Install Trigger RunAtReboot" >> /etc/DOAZLAB/DOAZLABLog
touch /etc/DOAZLAB/RunInstallToolsAtNextReboot

# Get updatd APT Pacakges and Upgrade
echo "Time: $(date). Updating Packages and Upgrading" >> /etc/DOAZLAB/DOAZLABLog 
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get upgrade -y


# Reboot
echo "Time: $(date). Rebooting" >> /etc/DOAZLAB/DOAZLABLog 
shutdown -r +1