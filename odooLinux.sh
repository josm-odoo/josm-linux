#!/bin/bash

# Open a terminal window for input
echo "Opening terminal window..."

gnome-terminal -- bash -c '
    # Function to collect user inputs
    collect_inputs() {
        echo "Starting collect_inputs function..."
        read -p "Enter username: " username
        read -p "Enter PC nickname: " pc_nickname
        read -p "Enter hostname: " hostname
        read -sp "Enter password: " password
        echo
        read -p "Enter SSH authorized key (optional): " ssh_authorized_key
    
        # Generate autoinstall.yaml
        echo "Generating autoinstall.yaml..."
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
          echo "      pc-nickname: $pc_nickname" >> autoinstall.yaml
        fi
    
        # Add SSH authorized key if provided
        if [ ! -z "$ssh_authorized_key" ]; then
          echo "        authorized-keys:" >> autoinstall.yaml
          echo "          - $ssh_authorized_key" >> autoinstall.yaml
        fi
    
        # Add remaining autoinstall.yaml content
        echo "Adding network configuration..."
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
    }

    collect_inputs; read -p "Press Enter to exit..."
'
