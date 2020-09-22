#!/usr/bin/env bash

set -ve

bootstrap_file=archlinux-bootstrap-2020.09.01-x86_64.tar.gz
bootstrap_url=http://mirrors.xmission.com/archlinux/iso/2020.09.01/$bootstrap_url
sha1_sum=dead7955aeaf5e08132d4c7781947326fb7eb1a3

## Start Arch install

curl $bootstrap_url -O
if echo "$sha1_sum *$bootstrap_file" | sha1_sum 
then
  echo "Verified bootstrap sha1sum"
else
  exit
fi

tar -xzf $bootstrap_file -C /mnt

# Update mirrorlist to US Mirrors
curl https://www.archlinux.org/mirrorlist/?country=US&protocol=https&use_mirror_status=on | sed -e 's/^#Server/Server/' -e '/^#/d' > /tmp/root.x86_64/etc/pacman.d/mirrorlist

# Arch Chroot
/tmp/root.x86_64/bin/arch-chroot /tmp/root.x86_64/