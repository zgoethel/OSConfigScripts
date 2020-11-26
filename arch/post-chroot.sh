#!/bin/bash

app_name="OS Setup (post-chroot) - Arch Linux (x86_64)"

read -p "Enter a timezone (e.g. 'America/Chicago'): " time_zone

# Sync pacman and install some utilities
pacman -Syy
pacman -S neofetch htop jdk-openjdk vim git dosfstools grub

clear

# Set the system time-zone
ln -sf /usr/share/zoneinfo/$time_zone /etc/localtime
hwclock --systohc

# Select a locale from the locale file
read -p "The locale config will now open; uncomment your chosen locale (press enter)" temp
vim /etc/locale.gen

locale-gen

clear

# Set the system hostname to user selection
read -p "Enter a hostname (e.g. 'personal-pc'): " host_name
echo $host_name > /etc/hostname

# Write to hosts file for domain name
echo "" >> /etc/hosts
echo "127.0.0.1	localhost" >> /etc/hosts
echo "::1		localhost" >> /etc/hosts
echo "" >> /etc/hosts

echo "127.0.0.1 $host_name.localdomain $host_name" >> /etc/hosts

clear

# Set a new password
passwd

# Mount and format the boot partition
read -p "Enter the boot partition name: " boot_partition
mkfs.fat -F 32 $boot_partition
mount $boot_partition /mnt/boot

# Install and configure GRUB bootloader
grub-install --target=x86_64-efi --efi-directory=/mnt/boot --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg

clear

# Set up systemd DHCP services/resolution
net_config_file="/etc/systemd/network/20-wired.network"
echo "Default config for 'eth0' will be written to $net_config_file"
echo "[Match]"    > $net_config_file
echo "Name=eth0" >> $net_config_file
echo ""          >> $net_config_file

echo "[Network]" >> $net_config_file
echo "DHCP=yes"  >> $net_config_file

systemctl enable systemd-networkd.service
systemctl enable systemd-resolved.service

clear

read -p "Please reboot the system; upon reboot, log in and execute the post-reboot script (press enter)" temp

exit
