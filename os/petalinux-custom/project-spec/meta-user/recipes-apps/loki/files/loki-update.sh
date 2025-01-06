#!/bin/bash

# Source the general LOKI utilities
source /etc/profile.d/loki-aliases.sh
source /etc/profile.d/extra-loki-scripts.sh

# Process the input arguments
ARGS=$(getopt -o t:p:df:hi: --long target:,source-path:,source-dev:,source-file:,help,ignore-appname,dry-run,backup,restore,info: -n 'loki-update' -- "$@")
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
INFO=

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

                                            When used with --info, this is the target to be
                                            inspected. In this mode only, you can also supply
                                            'runtime' or a direct filepath for image.ub.

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
    --info <field>              (optional)  Return information about the image installed in the
                                            location specified in --target. <field> can be one of:
                                                app-name        Application name
                                                app-version     Application version
                                                loki-version    LOKI core code version
                                                time            Timestamp when image was packaged
                                                humantime           ^ but human readable
                                                all             Summarise everything

                                            For --info only, the --target can be specified as
                                            'runtime' to get information about the currently booted
                                            image.
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

6) Get information summary about the image in SD:

    loki-update.sh --target sd --info all

7> Get the package time of the image stored in flash, in a human-readable format:

    loki-update.sh --target flash --info humantime

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
		-i | --info ) INFO="$2"; shift 2 ;;
		--ignore-appname ) IGNORE_APPNAME=true; shift ;;
		--dry-run ) DRYRUN=true; shift ;;
		--backup ) BACKUP=true; shift ;;
		--restore ) RESTORE=true; shift ;;
		-h | --help ) usage; exit 0; shift ;;
	-- ) shift; break ;;
	* ) break ;;
	esac
done

function storage_device_to_path() {
    if [ $1 = 'emmc' ] || [ $1 = 'eMMC' ]; then
        SD_PATH=$EMMC_MOUNTPOINT
    elif [ $1 = 'sd' ] || [ $1 = 'SD' ]; then
        SD_PATH=$SD_MOUNTPOINT
    else
        echo "Unrecognised device $1"
        exit 1
    fi
}

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
    SOURCEPATH=$(storage_device_to_path $SOURCEDEV && echo $SD_PATH)
fi

# Process info requests
function get_flash_image_timestamp() {
    # This is much quicker and simpler than other metadata as it is from the top-level
    # FIT FDT and can be read directly from flash with fdt tools.
    local kernel_mtddev=$(mtd_label_to_device kernel)
    METADATA_TIMESTAMP=$(fdtget -t i $kernel_mtddev / timestamp)
}

function get_filesystem_image_metadata () {
    # $1 is image.ub location in a normally accessible filesystem (emmc or sd for example).

    # The timestamp is read from the top-level FIT image tree
    METADATA_TIMESTAMP=$(fdtget -t i $1 / timestamp)

    # These parts are read from the system device tree, part way through the image after
    # extraction with dumpimage.
    METADATA_APPLICATION_NAME=$(dumpimage -T flat_dt -p 1 $1 -o /dev/stdout 2>/dev/null | fdtget -t s /dev/fd/0 /loki-metadata application-name)
    METADATA_APPLICATION_VERSION=$(dumpimage -T flat_dt -p 1 $1 -o /dev/stdout 2>/dev/null | fdtget -t s /dev/fd/0 /loki-metadata application-version)
    METADATA_LOKI_VERSION=$(dumpimage -T flat_dt -p 1 $1 -o /dev/stdout 2>/dev/null | fdtget -t s /dev/fd/0 /loki-metadata loki-version)
    METADATA_PLATFORM=$(dumpimage -T flat_dt -p 1 $1 -o /dev/stdout 2>/dev/null | fdtget -t s /dev/fd/0 /loki-metadata platform)
}

function get_flash_image_metadata() {
    # Recovery LOKI metadat from the loki-metadata part of the systen device tree. This
    # is at an unknown offset in the FIT image (image.ub) that is variable, and can only
    # be extracted from the file with dumpimage, after storing it temporarily.

    echo "Extracting flash metadata- this may take some time..." 1>&2

    local kernel_mtddev=$(mtd_label_to_device kernel)

    # Create a temporary workspace
    WORKSPACE=$(mktemp -d)

    # Extract the flash image into the workspace:
    cat $kernel_mtddev > $WORKSPACE/image.ub && dumpimage -T flat_dt -p 1 $WORKSPACE/image.ub -o $WORKSPACE/system.dtb

    # Extract the data
    METADATA_APPLICATION_NAME=$(fdtget -t s $WORKSPACE/system.dtb /loki-metadata application-name)
    METADATA_APPLICATION_VERSION=$(fdtget -t s $WORKSPACE/system.dtb /loki-metadata application-version)
    METADATA_LOKI_VERSION=$(fdtget -t s $WORKSPACE/system.dtb /loki-metadata loki-version)
    METADATA_PLATFORM=$(fdtget -t s $WORKSPACE/system.dtb /loki-metadata platform)

    # Delete the entire workspace
    rm -rf $WORKSPACE
}

function get_runtime_image_metadata() {
    # For the currently running image, we use the sysfs version of the device tree. Since
    # this does not contain the FIT header, we can't recover a timestamp. We could read the fdt
    # file stored at /sys/firmware/fdt, but unfortunately this can only be read by root, so
    # we instead access the properties directly.

    # Extract the data
    read -r -d '' METADATA_APPLICATION_NAME </sys/firmware/devicetree/base/loki-metadata/application-name || [[ $METADATA_APPLICATION_NAME ]]
    read -r -d '' METADATA_APPLICATION_VERSION </sys/firmware/devicetree/base/loki-metadata/application-version || [[ $METADATA_APPLICATION_VERSION ]]
    read -r -d '' METADATA_LOKI_VERSION </sys/firmware/devicetree/base/loki-metadata/loki-version || [[ $METADATA_LOKI_VERSION ]]
    read -r -d '' METADATA_PLATFORM </sys/firmware/devicetree/base/loki-metadata/platform || [[ $METADATA_PLATFORM ]]
}

if [ ! -z $INFO ] ; then
    if [ $TARGET = 'flash' ]; then
        # Retreive metadata from flash into env variables
        get_flash_image_timestamp

        # Retrieving anything other than the timestamp requires actually extracting the file
        # to process it, as the dumpimage tool will not work on devices that cannot seek.
        if [ ! $INFO = 'time' ] && [ ! $INFO = 'humantime' ]; then
            get_flash_image_metadata
        fi

    elif [ $TARGET = 'emmc' ] || [ $TARGET = 'sd' ]; then
        # Must be emmc or sd
        get_filesystem_image_metadata $(storage_device_to_path $TARGET && echo $SD_PATH)/image.ub
    elif [ $TARGET = 'runtime' ] ; then
        # Extract information about the currently booted image from the live devicetree
        get_runtime_image_metadata
    else
        # Must be just a generic path where image.ub is
        get_filesystem_image_metadata $TARGET
    fi


    # Print out the data asked for
    if [ $INFO = 'time' ]; then
        echo $METADATA_TIMESTAMP
        exit 0
    elif [ $INFO = 'humantime' ]; then
        echo $(date -d @$METADATA_TIMESTAMP)
        exit 0
    elif [ $INFO = 'app-name' ]; then
        echo $METADATA_APPLICATION_NAME
        exit 0
    elif [ $INFO = 'app-version' ]; then
        echo $METADATA_APPLICATION_VERSION
        exit 0
    elif [ $INFO = 'loki-version' ]; then
        echo $METADATA_LOKI_VERSION
        exit 1
    elif [ $INFO = 'all' ]; then
        echo "image info in $TARGET:"
        if [ ! -z $METADATA_TIMESTAMP ] ; then
            echo -e "\ttimestamp: $(date -d @$METADATA_TIMESTAMP)"
        else
            echo -e "\ttimestamp: Unknown"
        fi
        echo -e "\tApplication name: $METADATA_APPLICATION_NAME"
        echo -e "\tApplication version: $METADATA_APPLICATION_VERSION"
        echo -e "\tLOKI core version: $METADATA_LOKI_VERSION"
        echo -e "\tHardware Platform: $METADATA_PLATFORM"
        exit 0
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
