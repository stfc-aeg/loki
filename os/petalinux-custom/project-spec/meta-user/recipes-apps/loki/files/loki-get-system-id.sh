#!/bin/sh
### BEGIN INIG INFO
# Provides              lokisystemid
# Required-Start        autoformatemmc
# Required-Stop
# Default-Start         S 1 2 3 4 5
# Default-Stop          0 6
# Short-Description:    Recover System ID unique to LOKI carrier board and make accessible in /etc/loki/system-id

### END INIT INFO

# System ID is supposed to uniquely identify the control board / detector system.

# By default, to ensure that from factory the board has a unique identifier, this is dervied from the
# serial number of the eMMC module present on the board. However, it is possible to override the system
# ID to something more human-readable by creating a loki-config/system-id file in the eMMC mount (currently
# /mnt/sd-mmcblk0p1/loki-config/system-id), which will take precedence.
EMMC_CONFIG_DIR=/mnt/sd-mmcblk0p1/loki-config

EMMC_SERIALNO=$(cat /sys/class/mmc_host/mmc0/mmc0\:0001/serial)

if [ -f ${EMMC_CONFIG_DIR}/system-id ]
then
    echo "System ID override file found in eMMC"
    LOKI_SYSTEMID="$(cat ${EMMC_CONFIG_DIR}/system-id)"
else
    echo "Using eMMC UID for System ID"
    LOKI_SYSTEMID="${EMMC_SERIALNO}"
fi
echo "LOKI System ID is ${LOKI_SYSTEMID}"

# Now the system ID is recovered, put it where other parts of the system will know to read it from
echo ${LOKI_SYSTEMID} > /etc/loki/system-id
