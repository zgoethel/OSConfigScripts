#!/bin/bash

app_name="OS Setup - Arch Linux (x86_64)"

# Update system time clock
timedatectl set-ntp true

# Sync packages and install utilities
pacman -Syy
pacman -S vim dosfstools grub efibootmgr git #dialog

# Disk partitioning; obtain list of devices
device_list=($(fdisk -l | awk -F"Disk /dev/|: .*B, .*sectors" '$2 {print "/dev/" $2}'))

#dialog --backtitle "$app_name"\
#	--title "Drive Partitioning"\
#	--radiolist "Select a drive to partition" 0 0 0\
#	$(\
#		for i in "${!device_list[@]}";\
#		do\
#			echo "$i ${device_list[i]} $(if [ "$i" -eq "0" ]; then echo "on"; else echo "off"; fi) ";\
#		done\
#	)

# Disk partitioning loop
while [[ true ]]
do
	# Print disk details and ask for selection
	echo "Select a disk to partition (blank to continue):"
	fdisk -l | awk -F"Disk /dev/" '$2 {print "    /dev/" $2}'

	read -p "> (disk name) " disk_name
	
	# Exit when empty string entered
	if [[ -z $disk_name ]]
	then
		break
	fi
	
	# Trigger disk partitioning utility
	cfdisk $disk_name
done

# Read in and format root partition
read -p "Specify a root partition (format ext4): " root_partition
mkfs.ext4 $root_partition
mount $root_partition /mnt

# Read in and set up swap partition
read -p "Specify a swap partition (swapon): " swap_partition
mkswap $swap_partition
swapon $swap_partition

# Initial setup of mounted root partition
pacstrap /mnt base linux linux-firmware
genfstab -U /mnt >> /mnt/etc/fstab

cd /mnt
git clone https://github.com/zgoethel/OSConfigScripts.git

echo "Please execute 'arch-chroot /mnt' then run the post-chroot script"

# neofetch htop jdk-openjdk vim

#systemctl enable systemd-networkd.service
#systemctl enable systemd-resolved.service