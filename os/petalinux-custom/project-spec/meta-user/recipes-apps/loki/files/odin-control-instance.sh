CONFIG_DEFAULT_LOCATION="/etc/conf.d/loki-config/config-default.conf"
EXECUTABLE_NAME="odin_control"
PIDFILE_NAME="${2}.pid"
PIDFILE_PATH="/var/run/"
PIDFILE=$PIDFILE_PATH$PIDFILE_NAME
INSTANCE_CONFIG_FILE_NAME="${2}-config.conf"
INSTANCE_CONFIG_FILE_PATH="/etc/conf.d/loki-config/${INSTANCE_CONFIG_FILE_NAME}"
INSTANCE_INSTALL_DIR="${2}"

# Source the defaults file
source $CONFIG_DEFAULT_LOCATION

# Source the override file
if test -f $INSTANCE_CONFIG_FILE_PATH; then
    source $INSTANCE_CONFIG_FILE_PATH
fi

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

    echo "Executing from $conf_ODIN_DETECTOR_ROOT_LOC$INSTANCE_INSTALL_DIR with config $conf_ODIN_DETECTOR_ROOT_LOC$INSTANCE_INSTALL_DIR/config.cfg"
    cd $conf_ODIN_DETECTOR_ROOT_LOC$INSTANCE_INSTALL_DIR

    echo "Logging to $conf_ODIN_DETECTOR_LOGDESTINATION"
    # Create the default logging location directory with permission for the LOKI user to write.
    mkdir -p /var/log/loki
    chown $conf_LOKI_USERNAME /var/log/loki

    # Remove the old PID file
    rm -rf $PIDFILE

    set -x
    start-stop-daemon -S \
        -b \
        -p $PIDFILE -m \
        -c $conf_LOKI_USERNAME \
        -x "/bin/bash" \
        -- -c "exec $EXECUTABLE_NAME \
	--logging=$conf_ODIN_DETECTOR_LOGLEVEL \
	--log_file_prefix=$conf_ODIN_DETECTOR_LOGDESTINATION$2 \
	--config=$conf_ODIN_DETECTOR_ROOT_LOC$2/$INSTANCE_INSTALL_DIR/config.cfg \
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
