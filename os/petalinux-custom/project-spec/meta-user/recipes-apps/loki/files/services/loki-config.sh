#!/bin/sh
### BEGIN INIG INFO
# Provides              lokiconfig
# Required-Start        $networking lokibootstrapemmc lokicontrolhost
# Required-Stop
# Default-Start         S 1 2 3 4 5
# Default-Stop          0 6
# Short-Description:    LOKI External Configuration Manager

### END INIT INFO

OVERRIDE_CONFIGURATION_LOCATION="/mnt/emmc/loki-config/"

OVERRIDE_CONFIGURATION_FILENAME="loki-system-config.conf"
CONFIG_DEFAULT_LOCATION="/etc/conf.d/loki-config/loki-system-config-default.conf"
SSHCONFDIR_EMMC="/mnt/emmc/.ssh"
SSHCONFDIR_IMG="/home/${LOKI_USERNAME}/.ssh"
STATIC_IP_INTERFACE_NAME="eth0"
CONFIG_VERSION=1

# Determine if the remote configuration can be found. If not, attempt to copy the default config
# to the remote location, and otherwise start using the default config
if test -f "$OVERRIDE_CONFIGURATION_LOCATION$OVERRIDE_CONFIGURATION_FILENAME"; then
    # Load the external configuration file
    echo "Found external configuration at $OVERRIDE_CONFIGURATION_LOCATION$OVERRIDE_CONFIGURATION_FILENAME"

    # Source the defaults file
    source $CONFIG_DEFAULT_LOCATION

    # Source the override file
    source $OVERRIDE_CONFIGURATION_LOCATION$OVERRIDE_CONFIGURATION_FILENAME

else
    echo "Failed to find external configuration at $OVERRIDE_CONFIGURATION_LOCATION$OVERRIDE_CONFIGURATION_FILENAME"

    if test -d "$OVERRIDE_CONFIGURATION_LOCATION"; then
        # If the external configuration directory exists (but the file does not), copy the
        # default configuration to the directory
        echo "Configuration directory found, but no configuration."
        echo "Copying default config to $OVERRIDE_CONFIGURATION_LOCATION"
        cp $CONFIG_DEFAULT_LOCATION $OVERRIDE_CONFIGURATION_LOCATION$OVERRIDE_CONFIGURATION_FILENAME
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
