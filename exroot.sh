#!/bin/bash
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
GRAY='\033[0;37m'
NC='\033[0m' # No Color



echo "Running as root..."
sleep 2
clear


### Update Packages ###

opkg update
sleep 2
## Install Some Package for USB Driver ###

opkg install block-mount kmod-fs-ext4 e2fsprogs parted kmod-usb-storage
sleep 2

## Partitioning and formatting ###

DISK="/dev/sda"
sleep 2

parted -s /dev/sda -- mklabel gpt mkpart extroot 2048s -2048s
sleep 2

DEVICE="${DISK}1"
sleep 2

mkfs.ext4 -L extroot ${DEVICE}
sleep 2

### Configuring extroot ###

eval $(block info ${DEVICE} | grep -o -e 'UUID="\S*"')
eval $(block info | grep -o -e 'MOUNT="\S*/overlay"')
uci -q delete fstab.extroot
uci set fstab.extroot="mount"
uci set fstab.extroot.uuid="${UUID}"
uci set fstab.extroot.target="${MOUNT}"
uci commit fstab
sleep2

### Configuring rootfs_data ###

ORIG="$(block info | sed -n -e '/MOUNT="\S*\/overlay"/s/:\s.*$//p')"
uci -q delete fstab.rwm
uci set fstab.rwm="mount"
uci set fstab.rwm.device="${ORIG}"
uci set fstab.rwm.target="/rwm"
uci commit fstab
sleep 2

### Transferring data ###

mount ${DEVICE} /mnt
tar -C ${MOUNT} -cvf - . | tar -C /mnt -xf -

echo "DONE"

sleep 5

reboot
