#!/usr/bin/env bash

## Tested using grml from grml.org

set -v

# specify drives
drive=$1
passphrase=$2

# # wipe the disk with random data
# cryptsetup open --type=plain --key-file=/dev/urandom $drive temp_crypt
# dd if=/dev/urandom of=/dev/mapper/temp_crypt bs=1M status=progress
# sleep 1
# cryptsetup close temp_crypt

set -e

#setup partition table
parted -s -a optimal $drive mklabel gpt \
mkpart ESP fat32 1MiB 600MiB \
set 1 boot on \
mkpart primary ext4 600MiB 800MiB \
mkpart primary ext4 800MiB 100% \
set 3 lvm on

sleep 1

#set devices
efi=${drive}1
boot=${drive}2
lvm=${drive}3

#Encrypt the System
echo -n $passphrase | cryptsetup luksFormat --type luks2 $lvm -d -
echo -n $passphrase | cryptsetup open $lvm lvm -d -

# Create the volume group
pvcreate /dev/mapper/lvm
vgcreate Arch /dev/mapper/lvm

# Create the logical volumes
lvcreate -L 4G Arch -n swap
lvcreate -l 100%FREE Arch -n root

# Format the file system
mkfs.ext4 /dev/mapper/Arch-root
mkswap /dev/mapper/Arch-swap

# Prepare the boot partition
echo -n $passphrase | cryptsetup luksFormat $boot -d -
echo -n $passphrase | cryptsetup open $boot cryptboot -d -

# Create the filesystem
mkfs.ext4 /dev/mapper/cryptboot

# Mount the partitions
mount /dev/mapper/Arch-root /mnt

swapon /dev/mapper/Arch-swap

mkdir /mnt/boot
mount /dev/mapper/cryptboot /mnt/boot

# Format the EFI partition
mkfs.fat -F32 $efi

# Create the EFI mount point
mkdir /mnt/boot/efi
mount $efi /mnt/boot/efi

# # Start Void install
# wget http://repo.voidlinux.eu/static/xbps-static-latest.x86_64-musl.tar.xz
# tar xf xbps-static-latest.x86_64-musl.tar.xz -C /mnt
# /mnt/usr/bin/xbps-install -Sy --repository=http://repo.voidlinux.eu/current -r /mnt base-system lvm2 cryptsetup grub-x86_64-efi vim

# # Chroot into void
# mount -t proc proc /mnt/proc
# mount -t sysfs sys /mnt/sys
# mount -o bind /dev /mnt/dev
# mount -t devpts pts /mnt/dev/pts
# cp chroot-setup.sh /mnt/
# cd /mnt
# chroot /mnt /chroot-setup.sh $passphrase
# rm /mnt/chroot-setup.sh