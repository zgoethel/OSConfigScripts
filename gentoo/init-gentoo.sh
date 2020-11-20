#!/bin/bash

cfdisk /dev/sda
# Set BIOS boot, EFI system, swap, and Linux root

# Boot partition is 'FAT32' for UEFI
mkfs.fat -F 32 /dev/sda2

# Swap partition setup
mkswap /dev/sda3
swapon /dev/sda3

# Root filesystem is 'ext4'
mkfs.ext4 /dev/sda4
mount /dev/sda4 /mnt/gentoo/
cd /mnt/gentoo/

# Update the system time
ntpd -q -g

# Open the stage 3 link in browser
links https://gentoo.org/downloads/mirrors/
# Unpack whichever stage 3 exists
tar xpvf stage3-*.tar.xz --xattrs-include='*.*' --numeric-owner

# Overwrite the portage config
mv ~/config/portage_make.conf ./etc/portage/make.conf
# Configure portage make settings
vi ./etc/portage/make.conf
# Echo mirrors into the config file
mirrorselect -i -o >> ./etc/portage/make.conf

# Copy over repository config file
mkdir --parents ./etc/portage/repos.conf/
cp ./usr/share/portage/config/repos.conf ./etc/portage/repos.conf/gentoo.conf
# Copy over the kernel config file
cp ~/config/kernel_hardened-min ./
# Copy over DNS info
cp --dereference /etc/resolv.conf ./etc/

# Mount necessary filesystems
mount --types proc /proc /mnt/gentoo/proc
mount --rbind /sys /mnt/gentoo/sys
mount --make-rslave /mnt/gentoo/sys
mount --rbind /dev /mnt/gentoo/dev
mount --make-rslave /mnt/gentoo/dev

# Switch to new extracted root filesystem
chroot /mnt/gentoo /bin/bash << "EOT"
source /etc/profile
export PS1="(chroot) ${PS1}"

# Mount boot partition
mount /dev/sda2 /boot/

# Sync Gentoo repositories
emerge-webrsync
emerge --sync --quiet
# Long-running command
emerge --ask --verbose --update --deep --newuse @world

# I live in 'America/Chicago' timezone
echo "America/Chicago" > /etc/timezone
emerge --config sys-libs/timezone-data

nano -w /etc/locale.gen
locale-gen
eselect locale list
eselect locale set 4

env-update && source /etc/profile && export PS1="(chroot) ${PS1}"

cp ./kernel_hardened-min /usr/src/linux/
emerge --ask sys-kernel/gentoo-sources
#emerge sys-apps/pciutils lzop app-arch/lz4

cd /usr/src/linux
mv kernel_hardened-min .config/
make oldconfig

EOT