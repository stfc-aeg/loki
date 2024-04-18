#!/bin/sh
### BEGIN INIG INFO
# Provides              lokicontrolhost
# Required-Start        $networking autoformatemmc lokisystemid
# Required-Stop
# Default-Start         S 1 2 3 4 5
# Default-Stop          0 6
# Short-Description:    LOKI Control PC Automatic Directory Mounting

### END INIT INFO

LOKI_CONFIG_DIR=/mnt/sd-mmcblk0p1/loki-config

# Settings from this file will be sourced, and will override default values in this file
REMOTE_CONFIGURATION_LOCATION=${LOKI_CONFIG_DIR}/loki-host.conf
if [ -f ${REMOTE_CONFIGURATION_LOCATION} ]
then
    echo "Found a LOKI host configuration override file at ${REMOTE_CONFIGURATION_LOCATION}, sourcing it"
    source ${REMOTE_CONFIGURATION_LOCATION}
fi

# IP of the host control PC and mount location that the system expects the host to provide
LOKI_CONTROLHOST_IP="${LOKI_CONTROLHOST_IP:=192.168.100.1}"
LOKI_CONTROLHOST_MOUNTPOINT="${LOKI_CONTROLHOST_MOUNTPOINT:=/opt/export/loki}"

# Where the control host's root export will be mounted into the LOKI system
LOKI_CONTROLHOST_DESTINATION="/controlhost"

# Application name of this device, derived from name embedded in filesystem image. Should not
# generally need to be overridden
if [ -f /etc/loki/application-name ]
then
    LOKI_APPNAME="$(cat /etc/loki/application-name)"
else
    echo "WARNING: there is no valid application name built into the image, using NOAPP"
    LOKI_APPNAME="NOAPP"
fi

# Recover System ID (unique to the lOKI carrier, and therefore typically the detector system itself), which should
# have been added by the for-purpose init script. This can be overridden, see loki-get-system-id.sh init script.
if [ -f /etc/loki/system-id ]
then
    LOKI_SYSTEMID="$(cat /etc/loki/system-id)"
else
    echo "This script cannot run without a valid System ID"
    return 1
fi

# Places where the bind mounted locations end up
LOKI_SEQUENCES_DESTINATION="/opt/loki-detector/sequences"
LOKI_EXPORTS_DESTINATION="/opt/loki-detector/exports"
LOKI_CONFIG_DESTINATION=${LOKI_CONFIG_DIR}/loki-config.conf
LOKI_IMAGE_UPDATE_DESTINATION="/opt/loki-update"

function resolve_host {
    printf "Scanning for control host at ${LOKI_CONTROLHOST_IP}..."
    if ping -W 1 -c 1 -q ${LOKI_CONTROLHOST_IP}
    then
        printf "found\n"
        return 0
    else
        printf "not found\n"
        return 1
    fi
}

function mount_root {
    # Root is network mounted
    echo "Creating root host control mountpoint at ${LOKI_CONTROLHOST_IP}:${LOKI_CONTROLHOST_MOUNTPOINT}"
    mkdir -p ${LOKI_CONTROLHOST_DESTINATION}
    mount -onolock ${LOKI_CONTROLHOST_IP}:${LOKI_CONTROLHOST_MOUNTPOINT} ${LOKI_CONTROLHOST_DESTINATION}
    echo "Control host mounted successfully"
}

function parse_host_layout_config {
    # Find the host layout file and process it

    # The host layout file is expected to be inside an application-specific directory within the root
    # mount. If this hasn't been created, create it automatically.
    if [ -d ${LOKI_CONTROLHOST_DESTINATION}/${LOKI_APPNAME} ]
    then
        echo "Found LOKI Application Name directory on host (${LOKI_APPNAME})"
    else
        echo "Did not find LOKI Application Name directory on host, creating ${LOKI_APPNAME}"
        mkdir -p ${LOKI_CONTROLHOST_DESTINATION}/${LOKI_APPNAME} && \
            chown loki:loki ${LOKI_CONTROLHOST_DESTINATION}/${LOKI_APPNAME} && \
            chmod -R a+rw ${LOKI_CONTROLHOST_DESTINATION}/${LOKI_APPNAME}
        echo "Created application directory successfully"
    fi
    MOUNTED_APPROOT=${LOKI_CONTROLHOST_DESTINATION}/${LOKI_APPNAME}

    # Search the application-specific directory for the layout file, which will determine the rest of
    # the folder structure. This serves to separate different detector system types on the same control
    # host.
    MOUNT_LAYOUT_FILE_LOC=${MOUNTED_APPROOT}/layout.conf
    if [ -e ${MOUNT_LAYOUT_FILE_LOC} ]
    then
        echo "Found control host layout file at ${MOUNT_LAYOUT_FILE_LOC}"
        source ${MOUNT_LAYOUT_FILE_LOC}
        echo "Sourced layout file"
    else
        echo "Failed to find layout file at ${MOUNT_LAYOUT_FILE_LOC}, adding an example config"
        # Upload an example configuration, with commented out active variables
        echo "# Example configuration

# Specify relative locations to the application root. \${LOKI_SYSTEMID} can be used in
# paths to separate detector-specific configuration (per LOKI carrier board irrespective
# of SoM).

# If enabled, automatically create a top level system ID directory on boot, if it does not
# already exist. At <Application Name>/\${LOKI_SYSTEMID}. Useful if you don't know the system
# ID already.
#CREATE_SYSTEM_ID_DIRECTORY=1

# Example: Use a shared sequences directory for all detectors for this application
#SEQUENCES_LOC=sequences

# Example: Use a sequences directory separated for each system ID used just for one system ID
#SEQUENCES_LOC=\${LOKI_SYSTEMID}/sequences

# Available variables:
#######################

# File path of main LOKI .conf file. Optional override.
#LOKI_CONFIG_FILENAME=loki-config.conf

# Directory of odin-sequences sequence files. If left unspecified will use the base sequences
# built into the image.
#SEQUENCES_LOC=sequences-shared

# Directory of Data Export Location for SPI data etc. Required to access exported data.
# Note that all users must have write permission to this directory.
#EXPORTS_LOC=data_out

# Directory of image update location, where new image.ub, boot.scr and BOOT.BIN files should
# be placed for automatic system update.
#IMAGE_UPDATE_LOC=image_update
        " > ${MOUNT_LAYOUT_FILE_LOC}.example
        return 1
    fi
    return 0
}

# Directory Hierarchy:
# --------------------
#
# - <mount>
#     - <application name> (required, created)
#         - <system id> (created automatically if CREATE_SYSTEM_ID_DIRECTORY=1)
#             - (other directories specified in layout file)
#         - (other directories specified in layout file)

function create_bind_mounts {
    # Subdirectories are bind mounted from the root mount, with relative locations. Some are optional, with
    # locations defined in the layout configuration file already sourced. If desired, these locations can
    # use the LOKI system ID.

    # Special Option: CREATE_SYSTEM_ID_DIRECTORY
    # If set, the target system will create a directory with its unique System ID, meaning the user can specify
    # configurations differently for each system by including ${LOKI_SYSTEMID} in the toplevel under application.
    # For example, they might specify ${LOKI_SYSTEMID}/sequences for a system-specific sequences directory.
    if [[ ${CREATE_SYSTEM_ID_DIRECTORY:=0} -eq 1 ]]
    then
        echo "Automatic creation of system ID top-level directories has been enabled"
        if [ -d ${MOUNTED_APPROOT}/${LOKI_SYSTEMID} ]
        then
            echo "System ID directory for this detector system is already present"
        else
            echo "System ID directory for this detector system does not exist, creating it"
            mkdir -p ${MOUNTED_APPROOT}/${LOKI_SYSTEMID} && \
                chown loki:loki ${MOUNTED_APPROOT}/${LOKI_SYSTEMID} && \
                chmod -R a+rw ${MOUNTED_APPROOT}/${LOKI_SYSTEMID}
        fi
    fi

    # Sequences
    # The sequences directory for odin-sequences.
    if [ -z ${SEQUENCES_LOC+x} ];
    then
        echo "No sequence directory specified, using internal version"
    else
        echo "A sequences directory has been specified at ${MOUNTED_APPROOT}/${SEQUENCES_LOC}"
        if [ -d ${MOUNTED_APPROOT}/${SEQUENCES_LOC} ]
        then
            echo "Sequences directory exists, bind mounting it"
            mount --bind ${MOUNTED_APPROOT}/${SEQUENCES_LOC} ${LOKI_SEQUENCES_DESTINATION}
        else
            echo "Could not find sequences directory at ${MOUNTED_APPROOT}/${SEQUENCES_LOC}, will not mount"
        fi
    fi

    # Exports
    # The directory that the system will use to output data (e.g. SPI image captures)
    # This must be able to be written by the loki user, so test this before mounting
    if [ -z ${EXPORTS_LOC+x} ];
    then
        echo "No exports directory specified, using internal version"
    else
        echo "An exports directory has been specified at ${MOUNTED_APPROOT}/${EXPORTS_LOC}"
        if [ -d ${MOUNTED_APPROOT}/${EXPORTS_LOC} ]
        then
            if su loki -c "touch ${MOUNTED_APPROOT}/${EXPORTS_LOC}/testwrite${LOKI_SYSTEMID} && rm -rf ${MOUNTED_APPROOT}/${EXPORTS_LOC}/testwrite${LOKI_SYSTEMID}"
            then
                echo "Exports directory exists, bind mounting it"
                mount --bind ${MOUNTED_APPROOT}/${EXPORTS_LOC} ${LOKI_EXPORTS_DESTINATION}
            else
                echo "loki user cannot write to specified exports directory, will not mount"
            fi
        else
            echo "Could not find exports directory at ${MOUNTED_APPROOT}/${EXPORTS_LOC}, will not mount"
        fi
    fi

    # Config File
    # The generic LOKI config file is a collection of misc settings defined in various variables,
    # by default located in the eMMC. This single file will be bind mounted if present, and is read
    # on startup of the main LOKI detector process.
    if [ -z ${LOKI_CONFIG_FILENAME+x} ];
    then
        echo "No loki config specified, using internal version"
    else
        echo "A loki config override has been specified at ${MOUNTED_APPROOT}/${LOKI_CONFIG_FILENAME}"
        if [ -f ${MOUNTED_APPROOT}/${LOKI_CONFIG_FILENAME} ]
        then
            echo "loki config exists, bind mounting it"
            mount --bind ${MOUNTED_APPROOT}/${LOKI_CONFIG_FILENAME} ${LOKI_CONFIG_DESTINATION}
        else
            echo "Could not find loki config at ${MOUNTED_APPROOT}/${LOKI_CONFIG_FILENAME}, will not mount"
        fi
    fi

    # Image Update Directory
    # This directory is used to stage updates for the LOKI system. Images can be placed here by any
    # control system, but installing staged updates is handled elsewhere.
    if [ -z ${LOKI_CONFIG_FILENAME+x} ];
    then
        echo "No image update directory specified, using internal version"
    else
        echo "An image update directory has been specified at ${MOUNTED_APPROOT}/${IMAGE_UPDATE_LOC}"
        if [ -d ${MOUNTED_APPROOT}/${IMAGE_UPDATE_LOC} ]
        then
            echo "image update directory exists, bind mounting it"
            mount --bind ${MOUNTED_APPROOT}/${IMAGE_UPDATE_LOC} ${LOKI_IMAGE_UPDATE_DESTINATION}
        else
            echo "Could not find image update directory at ${MOUNTED_APPROOT}/${LOKI_IMAGE_UPDATE_LOC}, will not mount"
        fi
    fi
}

function remove_bind_mounts {
    echo "Unmounting bind mounts from host NFS mount"

    if mountpoint -q ${LOKI_SEQUENCES_DESTINATION}
    then
        printf "Unmounting sequences..."
        umount ${LOKI_SEQUENCES_DESTINATION}
        echo "Unmounted sequences"
    fi

    if mountpoint -q ${LOKI_EXPORTS_DESTINATION}
    then
        printf "Unmounting exports..."
        umount ${LOKI_EXPORTS_DESTINATION}
        echo "Unmounted exports"
    fi

    if mountpoint -q ${LOKI_CONTROLHOST_DESTINATION}
    then
        printf "Unmounting the host NFS mount..."
        umount ${LOKI_CONTROLHOST_DESTINATION}
        echo "Unmounted host NFS mount"
    fi
}

function service_start {
    if resolve_host
    then
        if mount_root && parse_host_layout_config && create_bind_mounts
        then
            echo "Success setting up host"
        else
            echo "Failure while setting up host"
            return 1
        fi
    else
        echo "Couldn't find specified host, aborting host mount script"
        return 1
    fi
}

function service_stop {
    remove_bind_mounts
}

case "$1" in
    start)
        # Resolve the host, create mountpoints
        service_start
        ;;
    stop)
        # Remove the bind mounts, use local filesystem
        service_stop
        ;;
    restart|force-reload)
        service_stop
        service_start
        ;;
    *)
        # Must be called with start, stop or restart/force-reload
        N=/etc/init.d/$NAME
        echo "Usage: $N {start|stop|restart|force-reload}" >&2
        ;;
esac

# Deactivate python virtual environment if currently in one
if [[ "$VIRTUAL_ENV" != "" ]]
then
    deactivate
fi
