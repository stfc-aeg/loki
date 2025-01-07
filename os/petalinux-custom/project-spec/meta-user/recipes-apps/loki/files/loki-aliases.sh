# Comamands and Aliases for Generic LOKI Systems

# Aliases
alias loki_info='loki-update.sh --info all --target runtime'
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

function loki_set_static_ip {
	mkdir -p /mnt/sd-mmcblk0p1/interfaces-mmc
	echo "
# Create an alias that will work without DHCP, but won't override it
auto eth0:1
iface eth0:1 inet static
        name Ethernet static alias
        address ${1}
        netmask 255.255.255.0
" > /mnt/sd-mmcblk0p1/interfaces-mmc/auto-static-eth0.conf

	# The automatic bind mount will bind this to where interfaces will see it
	mount -a

	# Restart the networking process
	/etc/init.d/networking restart
}
