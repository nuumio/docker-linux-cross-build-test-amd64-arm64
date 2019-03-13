#!/bin/bash

set -e

RDISKPATH=/mnt/ramdisk-build-test

if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root" 
    exit 1
fi

mkdir -p ${RDISKPATH}
modprobe zram num_devices=1
echo 64G > /sys/block/zram0/disksize
mkfs.ext4 -q -m 0 -b 4096 -O sparse_super -L zram /dev/zram0
mount -o relatime,nosuid,discard /dev/zram0 ${RDISKPATH}/
mkdir -p ${RDISKPATH}/build-test
chmod 777 ${RDISKPATH}/build-test

