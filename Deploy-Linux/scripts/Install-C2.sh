#!/bin/bash


# Run as root, please, it's just easier that way
sudo -s


# Add folder, Download Scripts
mkdir /etc/DOAZLAB
cd /etc/DOAZLAB
wget https://raw.githubusercontent.com/dpcybuck/DO-LAB/main/Deploy-Linux/scripts/Install-Tools.sh
wget https://raw.githubusercontent.com/dpcybuck/DO-LAB/main/Deploy-Linux/scripts/RunAtReboot.sh
chmod +x Install-Tools.sh
chmod +x RunAtReboot.sh


# Add key
sudo -u doadmin mkdir -p "/home/doadmin/.ssh"
sudo chmod 700 "/home/doadmin/.ssh"
echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC1XxoXD/oHJU9hcJc4Gv0+1ZKXZrd4eyoqbG0RVMBwXfylc45OjI4oQswK0sQGthzw+kjUZb90dckPIOl0GFPZCsEvInnvBJaCjsS5wKsq7bohnRJUP8cDXXOh4yrCScMvBd8o1xKbPQvarf+kSrbp4pF3sdhqwPjfMOq0fjvUMuprfjiWVxOCmCefhyOtUgvRhFEQSSbtPN6SMtPqgRKmtXwsMNwUWWvOJXfrOQl5WJRoDcvHsz9NlR2NXLeBvAZw/XnYeUyCv2Qwl5TaFk6/L1uxshAgt1n86HOoJDnAdcXieHA3Hr6iAY+YhW5TIWN4OMp1MpJUHBCD67n8ANBa5tgByhcafNMPqHFiE2bo/zEHKz9nTkjNImChu/0n4hAWjrfJgooTC9oLa1ZyuvGLneYcuNasZBkBw255l0AFgrZez7rWqLDhyCxb4T1HHwcj0GScpyttAFAEKNTRVfy3DsNFaWkvwoa1a0Mghcvz/D07jL4vqW6gcvgvQ6aYABCFNMrF+3PFnAz/LUH7d0ntplXInM2pZmqHI4dacYUgf1bJI+aUFkT6X9weZZdwVoDyfK8m2Kp3WkZr3r8oKz65fw8q2nUtmuCDgOfUwOL8PNwl3orJsJn9kDVebKmbodP7TUILHJ4etbSaoIrlcmaO+KMbdjdX+hJ2b34SkIMpXQ== doadmin@Nux01" >> /home/doadmin/.ssh/authorized_keys
sudo chmod 600 "/home/doadmin/.ssh/authorized_keys"
sudo chown -R doadmin:doadmin "/home/doadmin/.ssh"

# Add Log
touch /etc/DOAZLAB/DOAZLABLog

## Add Crontab for RunAtReboot
echo "Time: $(date). Updating Crontab for RunAtReboot" >> /etc/DOAZLAB/DOAZLABLog
echo @reboot root /etc/DOAZLAB/RunAtReboot.sh >> /etc/crontab

#add RunOnceTrigger
echo "Time: $(date). Adding Tool Install Trigger RunAtReboot" >> /etc/DOAZLAB/DOAZLABLog
touch /etc/DOAZLAB/RunInstallToolsAtNextReboot

# Get updated APT Packages and Upgrade
echo "Time: $(date). Updating Packages and Upgrading" >> /etc/DOAZLAB/DOAZLABLog 
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get upgrade -y

# Reboot
echo "Time: $(date). Rebooting" >> /etc/DOAZLAB/DOAZLABLog 
shutdown -r +1