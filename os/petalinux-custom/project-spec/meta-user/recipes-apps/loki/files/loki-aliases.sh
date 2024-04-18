# Comamands and Aliases for Generic LOKI Systems

# Aliases
alias loki_info='cat /etc/loki/*'
alias loki_system_id='cat /etc/loki/system-id'

# Functions

function loki_set_system_id {
    # Set the new system ID by writing the override file in the eMMC
    mkdir -p /mnt/sd-mmcblk0p1/loki-config
    echo "$1" > /mnt/sd-mmcblk0p1/loki-config/system-id

    # Re-run the ID fetch script to update the running system
    /etc/init.d/loki-get-system-id.sh
}

function loki_restart_app {
    /etc/init.d/loki-config.sh restart
}

function loki_stop_app {
    /etc/init.d/loki-config.sh stop
}

function loki_remount_host {
    /etc/init.d/loki-connect-control-host.sh restart
}

function loki_update_image_flash {
    flashcp -v "$1" /dev/mtd2
}

function loki_update_image_emmc {
    cp "$1" /mnt/sd-mmcblk0p1/image.ub
}
