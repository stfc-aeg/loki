#!/bin/sh
### BEGIN INIT INFO
# Provides              autoformatemmc
# Required-Start
# Required-Stop
# Default-Start         S 1 2 3 4 5
# Default-Stop          0 6
# Short-Description:    Automatically formats the eMMC storage card if present and empty

### END INIT INFO

EMMC_ROOT_DEV=/dev/mmcblk0
EMMC_PARTITION_LOC=${EMMC_ROOT_DEV}p1

function find_device {
        # Check if the eMMC device has been created at all
        printf "Looking for device at ${EMMC_ROOT_DEV}..."
        if [ -e $EMMC_ROOT_DEV ]
        then
                printf "\tfound\n"
                return 0
        else
                printf "\tnot found\n"
                return 1
        fi
}

function check_disk_empty {
        # Return 0 if the disk is empty, and formatting should continue
        printf "Checking if disk ${EMMC_ROOT_DEV} has a partition already..."
        if [ -e ${EMMC_PARTITION_LOC} ]
        then
                printf "\tFound partition at ${EMMC_PARTITION_LOC}\n"
                return 1
        else
                printf "\tNo existing partition at ${EMMC_PARTITION_LOC}, disk is empty\n"
        fi
}

function create_new_partition {
        # Create the label (partition table)
        printf "Re-creating the label (partition table)\n"
        parted --script -a optimal ${EMMC_ROOT_DEV} mklabel msdos

        # Create the new partition
        printf "Creating partition 1\n"
        parted --script -a optimal ${EMMC_ROOT_DEV} mkpart primary 8192B 100%

        # Format the partition
        printf "Formatting partition 1\n"
        mkfs.vfat ${EMMC_PARTITION_LOC}
}

if find_device
then
        if check_disk_empty
        then
                create_new_partition
                printf "New partition successfully created, eMMC is ready for use after reboot\n"
                reboot
        else
                printf "Disk already has a partition, Aborting...\n"
                exit
        fi

else
        printf "Could not locate eMMC device, Aborting...\n"
        exit
fi
