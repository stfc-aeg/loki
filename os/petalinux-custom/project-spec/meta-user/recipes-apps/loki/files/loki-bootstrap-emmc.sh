#!/bin/sh
### BEGIN INIT INFO
# Provides              autoformatemmc
# Required-Start
# Required-Stop
# Default-Start         S 1 2 3 4 5
# Default-Stop          0 6
# Short-Description:    Formats and partitions eMMC storage card if empty, and bootstraps it otherwise

### END INIT INFO

EMMC_DEVICE_NAME=mmcblk0
EMMC_PARTITION_NAME=${EMMC_DEVICE_NAME}p1
EMMC_ROOT_DEV=/dev/${EMMC_DEVICE_NAME}
EMMC_PARTITION_LOC=/dev/${EMMC_PARTITION_NAME}
EMMC_AUTOMOUNT_LOC=/mnt/sd-${EMMC_PARTITION_NAME}

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

function first_time_setup {
        # Temporarily mount
        mkdir -p /mnt/emmc_setup
        mount ${EMMC_PARTITION_LOC} /mnt/emmc_setup

        # Create the non-volatile network interfaces directory
        mkdir -p /mnt/emmc_setup/interfaces-mmc

        # Unmount
        umount /mnt/emmc_setup
}

function run_time_setup {
        # Mount the non-volatile network interfaces directory (already specified in fstab)
        # This is a bind mount, so if the source doesn't exist It'll fail nicely.
        INTERFACES_SOURCE=${EMMC_AUTOMOUNT_LOC}/interfaces-mmc
        INTERFACES_DEST=/etc/network/interfaces-mmc
        if mount --bind ${INTERFACES_SOURCE} ${INTERFACES_DEST}
        then
                printf "Mounted non-volatile network configuration from eMMC, files: $(ls ${INTERFACES_DEST})\n"
        else
                printf "Failed to mount non-volatile network configuration from ${INTERFACES_SOURCE} to ${INTERFACES_DEST}\n"
        fi
}

if find_device
then
        if check_disk_empty
        then
                create_new_partition
                printf "New partition successfully created on eMMC\n"

                printf "Performing first-time eMMC setup\n"
                first_time_setup

				printf "eMMC first-time configuration complete, rebooting\n"
                reboot
        else
                printf "eMMC already has a partition, setting up...\n"
                if run_time_setup
                then
                        printf "eMMC configuration complete\n"
				else
                        printf "there was an error during eMMC configuration, check the contents\n"
                        exit 1
                fi
                exit
        fi

else
        printf "Could not locate eMMC device, Aborting...\n"
        exit
fi
