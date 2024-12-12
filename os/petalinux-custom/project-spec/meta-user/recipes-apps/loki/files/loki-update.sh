#!/bin/bash

# Source the general LOKI utilities
source /etc/profile.d/loki-aliases.sh
source /etc/profile.d/extra-loki-scripts.sh

# Process the input arguments
ARGS=$(getopt -o t:p:d:f:h --long target:,source-path:,source-dev:,source-file:,help,ignore-appname,dry-run,backup,restore -n 'loki-update' -- "$@")
eval set -- "$ARGS"

# Hard-coded locations used throughout the script
EMMC_MOUNTPOINT=/mnt/sd-mmcblk0p1
SD_MOUNTPOINT=/mnt/sd-mmcblk1p1

# Defaults
TARGET=emmc
SOURCEPATH=.
SOURCEDEV=
SOURCEFILE=
IGNORE_APPNAME=false
DRYRUN=false
BACKUP=false
RESTORE=false

function usage() {
	echo "
LOKI Update:
============
loki-update is used to upload the boot.scr, BOOT.BIN and image.ub boot files for LOKI systems to the
various availble boot devices.

Usage:
------

Required unless backing up:
    - t | --target <targetname>	(required)  Specify the target where boot files will end up.
                                            Should be flash, emmc or sd. Default is emmc.

One of the following required: (-d will override -p)
    - p | --source-path <path>	(optional)  Give a path to the boot files you are uploading,
                                            if they are not in your current working dir.
    - d | --source-dev          (optional)  Give the name of a source device rather than a
                                            path. Should be emmc or sd if uploading. flash is
                                            is allowed only if you are using --backup.

Optional:
    - f | --source-filename     (optional)  Give the filename of a single target (not the path),
                                            so that just that will be uploaded instead of all
                                            three. Compatible with both -p and -d.
    --ignore-appname            (optional)  Not yet implemented
    --dry-run                   (optional)  Simply print out the intended actions without
                                            carrying them out.
    --backup                    (optional)  Backup the contents of the image at the source device,
                                            not compatible with -p.
    --restore                   (optional)  Path and srcfile will be ignored, the image from
                                            backup will be written to the desired <target>.
    -h | --help                 (optional)  Display this usage message.

Examples:
---------

1) Update all files (boot.scr, BOOT.BIN, image.ub) to eMMC from the current directory,
	assuming that they are all present.

	loki-update.sh --source-path .

2) Update all files on the eMMC from a full set copied to the LOKI home directory:

	loki-update.sh --target emmc --source-path /home/loki/

3) Clone an installation from the SD card to the flash as a recovery image:

	loki-update.sh --target flash --source-path /mnt/sd-mmcblk1p1/

        or

	loki-update.sh --target flash --source-dev sd

4) Update only the eMMC kernel image from a file in the current working directory:

	loki-update.sh --target emmc --source-file image.ub --source-path .

5) Update the recovery image in flash with the current one from eMMC:

    loki-update.sh --target flash

"
}

# If there are no arguments, display the help and exit
if [ $# -eq 1 ] ; then
    usage
    exit 0
fi

while true; do
	case "$1" in
		-t | --target ) TARGET=$2; shift 2 ;;
		-p | --source-path ) SOURCEPATH=$2; shift 2 ;;
		-d | --source-dev ) SOURCEDEV=$2; shift 2 ;;
		-f | --source-file ) SOURCEFILE="$2"; shift 2 ;;
		--ignore-appname ) IGNORE_APPNAME=true; shift ;;
		--dry-run ) DRYRUN=true; shift ;;
		--backup ) BACKUP=true; shift ;;
		--restore ) RESTORE=true; shift ;;
		-h | --help ) usage; exit 0; shift ;;
	-- ) shift; break ;;
	* ) break ;;
	esac
done

# Process / check arguments (especially those that depend on each other)
if $BACKUP ; then
    # Check that a valid device has been chosen to back up, paths are not allowed. By
    # default (if no device is supplied), we will backup the image in eMMC, the default
    # boot device.
    if [ -z $SOURCEDEV ] ; then
        echo "No device specified while backing up, will back up the eMMC image"
        SOURCEDEV='emmc'
    fi
fi
if [ ! -z $SOURCEDEV ] ; then
    # If there is a device specified as the source, replace the path with it the device
    if [ $SOURCEDEV = 'emmc' ] || [ $SOURCEDEV = 'eMMC' ]; then
        SOURCEPATH=$EMMC_MOUNTPOINT
    elif [ $SOURCEDEV = 'sd' ] || [ $SOURCEDEV = 'SD' ]; then
        SOURCEPATH=$SD_MOUNTPOINT
    else
        echo "Unrecognised source device $SOURCEDEV"
        exit 1
    fi
fi


function update_mmc() {
	# Update an MMC target with a file
	# args:
	# $1: target name: emmc or sd
	# $2: source filename, full path

	# Check that the file name is one of the expected ones
	local TARGET=$(mmc_name_to_mountpoint $1)
	if [ ! -e $TARGET ] ; then
		echo "Mountpoint for $1 $TARGET could not be found"
		exit 1
    fi

	# Copy the file over (for mmc devices, they all just go in the root directory)
	local command="cp $2 $(mmc_name_to_mountpoint $1)/"

	if $DRYRUN ; then
		echo "DRYRUN: $command"
	else
		echo $command
		eval $command
        if [ $? -ne 0 ] ; then
            exit $?
        fi
	fi
}

function update_flash() {
	# Update the flash recovery image with a file.
	# The destination will be automatically determined, currently from the source filename.
	# args: $1 source filename, full path

	# Use the file extension to determine whether we're dealing with image.ub, boot.scr or BOOT.BIN, and
	# perform any other checks.
	local FILE_NAME=$(basename -- "$1")
	local FILE_EXTENSION=${FILE_NAME##*.}
	if [ $FILE_EXTENSION = "ub" ] ; then
		# We're assuming this is image.ub
		if [ ! $FILE_NAME = "image.ub" ] ; then
			echo "File with unexpected name ${FILE_NAME} treated as image.ub"
		fi

        echo "Updating the kernel image"
		local command="flashcp -v $1 $(mtd_label_to_device kernel)"

	elif [ $FILE_EXTENSION = "bin" ] || [ $FILE_EXTENSION = "BIN" ] ; then
		# We're assuming this is BOOT.BIN
		if [ ! $FILE_NAME = "BOOT.BIN" ] ; then
			echo "File with unexpected name ${FILE_NAME} treated as BOOT.BIN"
		fi

        echo "Updating the bootloader"
		local command="flashcp -v $1 $(mtd_label_to_device boot)"

	elif [ $FILE_EXTENSION = "scr" ] ; then
		# We're assuming this is boot.scr
		if [ ! $FILE_NAME = "boot.scr" ] ; then
			echo "File with unexpected name ${FILE_NAME} treated as boot.scr"
		fi

        echo "Updating the bootscript"
		local command="flashcp -v $1 $(mtd_label_to_device bootscr)"
	else
		echo "Could not determine where to put file $1, exiting..."
		exit 1
	fi

	if $DRYRUN ; then
		echo "DRYRUN: $command"
	else
		echo $command
		eval $command
        if [ $? -ne 0 ] ; then
            exit $?
        fi
	fi
}

# Check that the source file(s) exist. If not specified, assume that we're copying image.ub, boot.scr and BOOT.BIN
if [ "$TARGET" = "emmc" ] || [ "$TARGET" = "sd" ] ; then
	# We are flashing eMMC or the SD card, both mmc devices

	# If we have supplied a specfic file, simply update this. Otherwise, all three
	if [ -z $SOURCEFILE ] ; then
		update_mmc $TARGET $SOURCEPATH/image.ub
		update_mmc $TARGET $SOURCEPATH/BOOT.BIN
		update_mmc $TARGET $SOURCEPATH/boot.scr
	else
		update_mmc $TARGET $SOURCEFILE
	fi
elif [ "$TARGET" = "flash" ] ; then
	# We are flashing the recovery image to flash

	# If we have supplied a specific file, simply update this. Otherwise, all three
	if [ -z $SOURCEFILE ] ; then
		update_flash $SOURCEPATH/boot.scr
		update_flash $SOURCEPATH/BOOT.BIN
		update_flash $SOURCEPATH/image.ub
	else
		update_flash $SOURCEFILE
	fi
else
    #TODO handle backing up and restoring
	echo "Unrecognised target $TARGET"
	exit 1
fi

exit 0
