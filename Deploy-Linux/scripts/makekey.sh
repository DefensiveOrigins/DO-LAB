#!/bin/bash

# Define the target user
USER="doadmin"
USER_HOME="/home/$USER"

# Generate a new SSH key pair (without passphrase)
sudo -u $USER ssh-keygen -t rsa -b 4096 -f "$USER_HOME/.ssh/id_rsa" -N ""

# Ensure the .ssh directory exists and has the correct permissions
sudo -u $USER mkdir -p "$USER_HOME/.ssh"
sudo chmod 700 "$USER_HOME/.ssh"

# Add the new public key to authorized_keys
sudo -u $USER cat "$USER_HOME/.ssh/id_rsa.pub" >> "$USER_HOME/.ssh/authorized_keys"

# Set appropriate permissions for authorized_keys
sudo chmod 600 "$USER_HOME/.ssh/authorized_keys"

# Ensure ownership is correct
sudo chown -R $USER:$USER "$USER_HOME/.ssh"

echo "SSH key has been generated and added to authorized_keys for $USER."










