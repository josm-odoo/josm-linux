#!/bin/bash

# Python script embedded within bash script
python_output=$(python3 - <<END
# Python code starts here
# Replace this section with your actual Python script

# Sample Python code to collect user inputs
username = input("Enter username: ")
pc_nickname = input("Enter PC nickname: ")
hostname = input("Enter hostname: ")
password = input("Enter password: ")
ssh_authorized_key = input("Enter SSH authorized key (optional): ")

# Output variables in the required format
print(f"Username: {username}")
print(f"PC Nickname: {pc_nickname}")
print(f"Hostname: {hostname}")
print(f"Password: {password}")
print(f"SSH Authorized Key: {ssh_authorized_key}")

# Python code ends here
END
)

# Extract variables from Python output
username=$(echo "$python_output" | awk '/Username:/ {print $2}')
pc_nickname=$(echo "$python_output" | awk '/PC Nickname:/ {print $3}')
hostname=$(echo "$python_output" | awk '/Hostname:/ {print $2}')
password=$(echo "$python_output" | awk '/Password:/ {print $2}')
ssh_authorized_key=$(echo "$python_output" | awk '/SSH Authorized Key:/ {print $4}')

# Generate autoinstall.yaml
cat <<EOF > autoinstall.yaml
# autoinstall.yaml

# Identity configuration
identity:
  hostname: $hostname           # Set the hostname
  username: $username           # Set the username
  password: $password           # Set the user's password
  ssh:
    allow-pw: true             # Allow password authentication for SSH
EOF

# Add PC nickname if provided
if [ ! -z "$pc_nickname" ]; then
  echo "  pc-nickname: $pc_nickname" >> autoinstall.yaml
fi

# Add SSH authorized key if provided
if [ ! -z "$ssh_authorized_key" ]; then
  echo "    authorized-keys:" >> autoinstall.yaml
  echo "      - $ssh_authorized_key" >> autoinstall.yaml
fi

# Add remaining autoinstall.yaml content
cat <<EOF >> autoinstall.yaml

# Network configuration
network:
  network:
    version: 2
    ethernets:
      ens33:
        dhcp4: true         # Use DHCP for networking

# Storage configuration
storage:
  grub:
    reorder_uefi: True
  layout:
    name: direct
  swap:
    size: 2G
  config:
    - type: disk
      id: disk0
      ptable: gpt
      match:
        size: largest
      wipe: superblock
      grub_device: true
    - type: partition
      id: root
      device: disk0
      size: 512M
      flag: boot
    - type: partition
      id: swap
      device: disk0
      size: 2G
      flag: swap
    - type: partition
      id: home
      device: disk0
      size: 100%
      flag: ""
  filesystems:
    - device: disk0p1
      format: ext4
      path: /
    - device: disk0p3
      format: ext4
      path: /home

# Packages to install
packages:
  - ubuntu-desktop

# Late commands
late-commands:
  - echo "Installation complete." > /target/installation-complete.txt
EOF

echo "autoinstall.yaml generated successfully."
