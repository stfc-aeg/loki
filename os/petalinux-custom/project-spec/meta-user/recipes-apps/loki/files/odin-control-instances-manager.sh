#!/bin/sh
### BEGIN INIT INFO
# Provides              odincontrolinstancesmanager
# Required-Start        lokiconfig
# Required-Stop
# Default-Start         S 1 2 3 4 5
# Default-Stop          0 6
# Short-Description:    Manage ODIN Control instances
### END INIT INFO

INSTANCES_PATH="/opt/loki-detector/instances"
CONFIG_DEFAULT_LOCATION="/etc/conf.d/loki-config/config-default.conf"

for DIR in $INSTANCES_PATH/*/; do
    # Source default config
    source $CONFIG_DEFAULT_LOCATION

    INSTANCE_NAME=$(basename $DIR)
    INSTANCE_CONFIG_FILE_NAME="${INSTANCE_NAME}-config.conf"
    INSTANCE_CONFIG_FILE_PATH="/etc/conf.d/loki-config/${INSTANCE_CONFIG_FILE_NAME}"

    # Source the override file
    if test -f $INSTANCE_CONFIG_FILE_PATH; then
        source $INSTANCE_CONFIG_FILE_PATH
    fi

    case "$1" in
        start)
            if [ $conf_AUTO_START = true ]; then
                odin-control-instance.sh start $(basename $DIR)
            fi
            ;;
        stop)
            odin-control-instance.sh stop $(basename $DIR)
            ;;
        restart|force-reload)
            odin-control-instance.sh stop $(basename $DIR)
            if [ $conf_AUTO_START = true ]; then
                odin-control-instance.sh start $(basename $DIR)
            fi
            ;;
        *)
            N=/etc/init.d/$NAME
            echo "Usage: $N {start|stop|restart|force-reload}" >&2
            ;;
    esac
done