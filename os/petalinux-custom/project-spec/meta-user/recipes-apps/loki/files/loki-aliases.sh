# Comamands and Aliases for Generic LOKI Systems

# Aliases
alias loki_info='loki-update.sh --info all --target runtime'
alias loki_system_id='cat /etc/loki/system-id'

# Functions

function loki_set_system_id {
    # Set the new system ID by writing the override file in the eMMC
    mkdir -p /mnt/emmc/loki-config
    echo "$1" > /mnt/emmc/loki-config/system-id

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
	mkdir -p /mnt/emmc/wired-network-overrides-mmc
	echo "
# Create an alias that will work without DHCP, but won't override it
[Address]
Address=${1}/24
" > /mnt/emmc/wired-network-overrides-mmc/auto-static-eth0.conf

	# The automatic bind mount will bind this to where interfaces will see it
	mount -a

	# Restart the networking process
    networkctl reload
}
