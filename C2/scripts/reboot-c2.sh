#!/bin/bash

# Run as root, please, it's just easier that way
sudo -s

# update from first boot
apt update
apt upgrade -y

reboot -h now