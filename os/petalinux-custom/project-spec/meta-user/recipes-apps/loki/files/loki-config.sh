#!/bin/sh
### BEGIN INIG INFO
# Provides              lokiconfig
# Required-Start        $networking $autoformatemmc
# Required-Stop
# Default-Start         S 1 2 3 4 5
# Default-Stop          0 6
# Short-Description:    LOKI External Configuration Manager

### END INIT INFO

#REMOTE_CONFIGURATION_LOCATION="/mnt/flashmtd1/loki-config/"
REMOTE_CONFIGURATION_LOCATION="/mnt/sd-mmcblk0p1/loki-config/"

REMOTE_CONFIGURATION_FILENAME="loki-config.conf"
CONFIG_DEFAULT_LOCATION="/etc/conf.d/loki-config/config-default.conf"
REMOTE_NETWORK_CONFIGURATION_FILENAME="interfaces"
NETWORK_CONFIG_DEFAULT_LOCATION="/etc/network/interfaces"
LOKI_USERNAME="loki"
SSHCONFDIR_FLASH="/mnt/flashmtd1/.ssh"
SSHCONFDIR_IMG="/home/${LOKI_USERNAME}/.ssh"
STATIC_IP_INTERFACE_NAME="eth0"
CONFIG_VERSION=1
EXECUTABLE_NAME="odin_control"
PIDFILE="/var/run/detector.pid"

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

#--------------------------------------------------------------------------------------------------------
# Perform network config override if desired

# Copy the existing filesystem default file to the destination, only if there is no file there. This is so
# that it can be edited, even if it is not currently in use.
remote_network_conf_found=0
remote_network_conf_path="$REMOTE_CONFIGURATION_LOCATION$REMOTE_NETWORK_CONFIGURATION_FILENAME"
if test -f "$remote_network_conf_path"; then
    echo "External network configuration file found at $remote_network_conf_path"
    remote_network_conf_found=1
else
    if test -d "$REMOTE_CONFIGURATION_LOCATION"; then
        # If the external configuration directory exists (but the file does not), copy the
        # default configuration to the directory
        echo "No external network configuration file found, but directory exists, copying $NETWORK_CONFIG_DEFAULT_LOCATION to $remote_network_conf_path"
        cp $NETWORK_CONFIG_DEFAULT_LOCATION $remote_network_conf_path
        remote_network_conf_found=1
    else
        # If the config location does not exist, abort and use the default live config
        echo "Configuration destination directory does not exist, must use internal config"
        remote_network_conf_found=0
    fi
fi

# Activate the external configuration, if actually present as well as enabled by the main config file
if [ "$conf_NETWORK_OVERRIDE_ENABLE" = "1" ] && [ $remote_network_conf_found = 1 ]; then
    echo "Overriding network configuration with interfaces file at $remote_network_conf_path"

    # Copy the destination file to the live system file to 'install'
    cp $remote_network_conf_path $NETWORK_CONFIG_DEFAULT_LOCATION || echo "Error in network config copy..."

    # Re-start the network configuration service
    /etc/init.d/networking restart

    echo "External network configuration installed and activated"
else
    echo "Using default network configuration (override enabled: $conf_NETWORK_OVERRIDE_ENABLE, found: $remote_network_conf_found)"
fi

# If the static IP has been specified, apply this *after* the config file. This way any other settings will
# be retained.
if [ "$conf_NETWORK_STATIC_IP_ENABLE" = "1" ]; then
    echo "Network configuration will be overridden with static IP $conf_NETWORK_STATIC_IP for interface $STATIC_IP_INTERFACE_NAME"
    ifconfig $STATIC_IP_INTERFACE_NAME $conf_NETWORK_STATIC_IP
fi

# If the loki user .ssh directory is to be persistent, create it in flash and bind mount over existing version
if [ "$conf_PERSISTENT_SSH_AUTH" = "1" ]; then
    echo "SSH authorized keys will persist between boots and image updates"

    # Make directories on flash as well as internal one if it does not exist
    mkdir -p ${SSHCONFDIR_FLASH}
    mkdir -p ${SSHCONFDIR_IMG}

    # If there are any keys already in the internal .ssh authorized_keys that do not appear in the flash
    # version, add them
    if test -f "${SSHCONFDIR_IMG}/authorized_keys"; then
        if test -f "${SSHCONFDIR_FLASH}/authorized_keys"; then
            # Append any keys that appear only in the internal file to the flash one
            cat ${SSHCONFDIR_IMG}/authorized_keys ${SSHCONFDIR_FLASH}/authorized_keys ${SSHCONFDIR_FLASH}/authorized_keys \
                | sort | uniq -u >> ${SSHCONFDIR_FLASH}/authorized_keys
        fi
    fi

    # Config and other files in flash will simply overwrite the image version

    # Bind mount the flash directory to the internal one
    mount --bind ${SSHCONFDIR_FLASH} ${SSHCONFDIR_IMG}
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

#-------------------------------------------------------------------------------------------------------
# Service Control

function service_start {
    echo "Starting LOKI detector"

    echo "Executing from $conf_ODIN_DETECTOR_ROOT_LOC with config $conf_ODIN_DETECTOR_CONFIG_LOC"
    cd $conf_ODIN_DETECTOR_ROOT_LOC

    echo "Logging to $conf_ODIN_DETECTOR_LOGDESTINATION"
    # Create the default logging location directory with permission for the LOKI user to write.
    mkdir -p /var/log/loki
    chown $LOKI_USERNAME /var/log/loki

    # Remove the old PID file
    rm -rf $PIDFILE

    set -x
    start-stop-daemon -S \
        -b \
        -p $PIDFILE -m \
        -c $LOKI_USERNAME \
        -x "/bin/bash" \
        -- -c "exec $EXECUTABLE_NAME \
	--logging=$conf_ODIN_DETECTOR_LOGLEVEL \
	--log_file_prefix=$conf_ODIN_DETECTOR_LOGDESTINATION \
	--config=$conf_ODIN_DETECTOR_CONFIG_LOC \
    --log_rotate_mode=size \
    --log_file_max_size=$conf_ODIN_DETECTOR_LOG_FILE_SIZE \
    --log_file_num_backups=$conf_ODIN_DETECTOR_LOG_FILE_NUM_BACKUPS \
    $conf_ODIN_DETECTOR_ADDITIONAL_ARGUMENTS \
	2>> $conf_ODIN_DETECTOR_STDERRDESTINATION"
    set +x

    echo "Launch complete"
}

function service_stop {
    echo "Stopping LOKI detector"

	if [ -f $PIDFILE ]; then

        start-stop-daemon -K \
            -p $PIDFILE

        while [ -d /proc/$(cat $PIDFILE) ]; do
            sleep 1
            echo "waiting..."
        done

        rm -rf $PIDFILE

        echo "Service stopped"
    else
        echo "Service was not running"
    fi
}

echo "Called with run argument ${1}"
case "$1" in
    start)
        service_start
        ;;
    stop)
        service_stop
        ;;
    restart|force-reload)
        service_stop
        service_start
        ;;
    *)
        N=/etc/init.d/$NAME
        echo "Usage: $N {start|stop|restart|force-reload}" >&2
        ;;
esac

# Deactivate python virtual environment if currently in one
if [[ "$VIRTUAL_ENV" != "" ]]
then
    deactivate
fi
