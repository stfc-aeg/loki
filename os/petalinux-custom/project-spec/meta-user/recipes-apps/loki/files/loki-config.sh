#!/bin/sh
### BEGIN INIG INFO
# Provides              lokiconfig
# Required-Start        $networking lokibootstrapemmc lokicontrolhost
# Required-Stop
# Default-Start         S 1 2 3 4 5
# Default-Stop          0 6
# Short-Description:    LOKI External Configuration Manager

### END INIT INFO

#REMOTE_CONFIGURATION_LOCATION="/mnt/flashmtd1/loki-config/"
REMOTE_CONFIGURATION_LOCATION="/mnt/sd-mmcblk0p1/loki-config/"

REMOTE_CONFIGURATION_FILENAME="loki-config.conf"
CONFIG_DEFAULT_LOCATION="/etc/conf.d/loki-config/config-default.conf"
SSHCONFDIR_EMMC="/mnt/sd-mmcblk0p1/.ssh"
SSHCONFDIR_IMG="/home/${LOKI_USERNAME}/.ssh"
STATIC_IP_INTERFACE_NAME="eth0"
CONFIG_VERSION=1

# Determine if the remote configuration can be found. If not, attempt to copy the default config
# to the remote location, and otherwise start using the default config
if test -f "$REMOTE_CONFIGURATION_LOCATION$REMOTE_CONFIGURATION_FILENAME"; then
    # Load the external configuration file
    echo "Found external configuration at $REMOTE_CONFIGURATION_LOCATION$REMOTE_CONFIGURATION_FILENAME"

    # Source the defaults file
    source $CONFIG_DEFAULT_LOCATION

    # Source the override file
    source $REMOTE_CONFIGURATION_LOCATION$REMOTE_CONFIGURATION_FILENAME

    # If the configuration asks for a production boot, source the default config instead
    if [ "$conf_OVERRIDE_PRODUCTION" = "0" ]; then
        echo "Configuration requests a production boot, using default config..."
        echo "Using the default configuration at $CONFIG_DEFAULT_LOCATION"
        source $CONFIG_DEFAULT_LOCATION
    fi

    # If the configuration asks for a disbled detector, abort
    if [ "$conf_DO_NOT_START" = "1" ]; then
        echo "Configuration has requested that detector should not start, aborting..."
        exit 0
    fi
else
    echo "Failed to find external configuration"

    if test -d "$REMOTE_CONFIGURATION_LOCATION"; then
        # If the external configuration directory exists (but the file does not), copy the
        # default configuration to the directory
        echo "Configuration directory found, but no configuration."
        echo "Copying default config to $REMOTE_CONFIGURATION_LOCATION"
        cp $CONFIG_DEFAULT_LOCATION $REMOTE_CONFIGURATION_LOCATION$REMOTE_CONFIGURATION_FILENAME
        echo "The configuration can now be modified."
    else
        # If the config location does not exist, abort and use default live config
        echo "Failed to find remote configuration, continuing in production (image) mode"
    fi

    echo "Using the default configuration at $CONFIG_DEFAULT_LOCATION"
    source $CONFIG_DEFAULT_LOCATION
fi

#--------------------------------------------------------------------------------------------------------
# Check the currently loaded config

# Check compatability of external configuration this script
if [ "$CONFIG_VERSION" -gt "$conf_CONFIG_VERSION" ]; then
    echo "Configuration out of date (version $conf_CONFIG_VERSION, vs system version $CONFIG_VERSION), aborting..."
    exit 1
fi

# If the loki user .ssh directory is to be persistent, create it in eMMC and bind mount over existing version
if [ "$conf_PERSISTENT_SSH_AUTH" = "1" ]; then
    echo "SSH authorized keys will persist between boots and image updates"

    # Make directories on eMMC as well as internal one if it does not exist
    mkdir -p ${SSHCONFDIR_EMMC}
    mkdir -p ${SSHCONFDIR_IMG}

    # If there are any keys already in the internal .ssh authorized_keys that do not appear in the eMMC
    # version, add them
    if test -f "${SSHCONFDIR_IMG}/authorized_keys"; then
        if test -f "${SSHCONFDIR_EMMC}/authorized_keys"; then
            # Append any keys that appear only in the internal file to the flash one
            cat ${SSHCONFDIR_IMG}/authorized_keys ${SSHCONFDIR_EMMC}/authorized_keys ${SSHCONFDIR_EMMC}/authorized_keys \
                | sort | uniq -u >> ${SSHCONFDIR_EMMC}/authorized_keys
        fi
    fi

    # Config and other files in flash will simply overwrite the image version

    # Bind mount the flash directory to the internal one
    mount --bind ${SSHCONFDIR_EMMC} ${SSHCONFDIR_IMG}
fi

#--------------------------------------------------------------------------------------------------------
# Execute the Initial Setup Script (Installation-specific)
if [ "$conf_INITIAL_SETUP_SCRIPT_ENABLE" = "1" ]; then
    echo "Executing initial setup script $conf_INITIAL_SETUP_SCRIPT_PATH"
    source $conf_INITIAL_SETUP_SCRIPT_PATH || echo "Error in startup script..."
    echo "Initial setup script complete"
else
    echo "No initial setup script in use"
fi

#--------------------------------------------------------------------------------------------------------
# Activate Python Virtual Environment
if [ "$conf_ODIN_DETECTOR_PYVENV_ENABLE" = "1" ]; then
    echo "Using Python virtual environment at $conf_ODIN_DETECTOR_PYVENV_PATH"
    source "${conf_ODIN_DETECTOR_PYVENV_PATH}/bin/activate"

    pip list
else
    echo "Using default Python environment"
fi
echo "Odin Server Binary Used: $(which odin_server)"