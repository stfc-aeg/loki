#!/bin/bash

# Source the general LOKI utilities
source /etc/profile.d/loki-aliases.sh
source /etc/profile.d/extra-loki-scripts.sh

# Process the input arguments
ARGS=$(getopt -o p:t:h --long target:,path:,srcfile:,help,ignore-appname,dry-run,backup,restore -n 'loki_update' -- "$@")
eval set -- "$ARGS"

# Defaults
TARGET=emmc
SOURCEPATH=.
SRCFILE=
IGNORE_APPNAME=false
DRYRUN=false
BACKUP=false
RESTORE=false

function usage() {
	echo "
LOKI Update:
============
loki_update is used to upload the boot.scr, BOOT.BIN and image.ub boot files for LOKI systems to the
various availble boot devices.

Usage:
------
	- t | --target <targetname>	(required)	Specify the target where boot files will end up.
							Should be flash, emmc or sd. Default is emmc.
	- p | --path <path>		(optional)	Give a path to the boot files you are uploading,
							if they are not in your current working dir.
	--srcfile			(optional)	Give the absolute filename of a target instead
							of a path, to just upload one of the three.
	--ignore-appname		(optional)	Not yet implemented
	--dry-run			(optional)	Simply print out the intended actions without
							carrying them out.
	--backup			(optional)	Instead of uploading to <target>, backup the
							contents of the image found there.
	--restore			(optional)	Path and srcfile will be ignored, the image from
							backup will be written to the desired <target>.
	-h | --help			(optional)	Display this usage message.

Examples:
---------

1) Update all files (boot.scr, BOOT.BIN, image.ub) to eMMC from the current directory,
	assuming that they are all present.

	loki_update.sh

1) Update all files on the eMMC from a full set copied to the LOKI home directory:

	loki_update.sh --target emmc -path /home/loki/

2) Clone an installation from the SD card to the flash as a recovery image:

	loki_update.sh --target flash -path /mnt/sd-mmcblk1p1/

3) Update only the eMMC kernel image from a file in the current working directory:

	loki_update.sh --target emmc --srcfile image.ub

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
		-p | --path ) SOURCEPATH=$2; shift 2 ;;
		--srcfile ) SRCFILE="$2"; shift 2 ;;
		--ignore-appname ) IGNORE_APPNAME=true; shift ;;
		--dry-run ) DRYRUN=true; shift ;;
		--backup ) BACKUP=true; shift ;;
		--restore ) RESTORE=true; shift ;;
		-h | --help ) usage; exit 0; shift ;;
	-- ) shift; break ;;
	* ) break ;;
	esac
done

#echo "TARGET ${TARGET}, PATH ${SOURCEPATH}, SRCFILE ${SRCFILE}, IGNORE_APPNAME ${IGNORE_APPNAME}"

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
			#TODO somehow rename the destination file
		fi

		local command="flashcp -v $1 $(mtd_label_to_device kernel)"

	elif [ $FILE_EXTENSION = "bin" ] || [ $FILE_EXTENSION = "BIN" ] ; then
		# We're assuming this is BOOT.BIN
		if [ ! $FILE_NAME = "BOOT.BIN" ] ; then
			echo "File with unexpected name ${FILE_NAME} treated as BOOT.BIN"
			#TODO somehow rename the destination file
		fi
		
		local command="flashcp -v $1 $(mtd_label_to_device boot)"

	elif [ $FILE_EXTENSION = "scr" ] ; then
		# We're assuming this is boot.scr
		if [ ! $FILE_NAME = "boot.scr" ] ; then
			echo "File with unexpected name ${FILE_NAME} treated as boot.scr"
			#TODO somehow rename the destination file
		fi

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
	if [ -z $SRCFILE ] ; then
		update_mmc $TARGET $SOURCEPATH/image.ub
		update_mmc $TARGET $SOURCEPATH/BOOT.BIN
		update_mmc $TARGET $SOURCEPATH/boot.scr
	else
		update_mmc $TARGET $SRCFILE
	fi
elif [ "$TARGET" = "flash" ] ; then
	# We are flashing the recovery image to flash

	# If we have supplied a specific file, simply update this. Otherwise, all three
	if [ -z $SRCFILE ] ; then
		update_flash $SOURCEPATH/boot.scr
		update_flash $SOURCEPATH/BOOT.BIN
		update_flash $SOURCEPATH/image.ub
	else
		update_flash $SRCFILE
	fi
else
	echo "Unrecognised target $TARGET"
	exit 1
fi

exit 0
