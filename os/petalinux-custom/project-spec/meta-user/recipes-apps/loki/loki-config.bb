SUMMARY = "Installer for generic LOKI setup script, which facilitates the configuration of a non-volatile debug setup."

RDEPENDS:${PN} += "loki-config"

# Repo URL.
SRC_URI = "file://loki-config.sh \
    file://loki-bootstrap-emmc.sh \
    file://loki-connect-control-host.sh \
    file://loki-get-system-id.sh \
    file://loki-system-config-default.conf \
    file://instance-config-default.conf \
    file://odin-control-instance.sh \
    file://odin-control-instances-manager.sh \
    "

# This has to be in the format expected in Yocto's license list...
LICENSE = "CLOSED"

DEFAULT_CONFIG_NAME = "loki-system-config-default.conf"
DEFAULT_INSTANCE_CONFIG_NAME = "instance-config-default.conf"

# General LOKI startup script for odin-control
STARTUP_SCRIPT_NAME = "loki-config.sh"
STARTUP_SCRIPT_RUNLEVEL = "5"

# Start-up script to format the eMMC on first carrier boot, or if the partition is deleted
EMMC_SCRIPT_NAME = "loki-bootstrap-emmc.sh"
EMMC_SCRIPT_RUNLEVEL = "S"

# Start-up script to initialise a connection to a control host PC, mounting relevant
CONTROLHOST_SCRIPT_NAME = "loki-connect-control-host.sh"
CONTROLHOST_SCRIPT_RUNLEVEL = "5"

# Start-up script to determine the board-unique System ID, and store it in /etc/loki/system-id
SYSID_SCRIPT_NAME = "loki-get-system-id.sh"
SYSID_SCRIPT_RUNLEVEL = "5"

# Script to start odin-control instances
ODIN_CONTROL_INSTANCE_SCRIPT_NAME = "odin-control-instance.sh"

# odin-control instances manager init script
ODIN_CONTROL_INSTANCES_MANAGER_SCRIPT_NAME = "odin-control-instances-manager.sh"
ODIN_CONTROL_INSATNCES_MANAGER_SCRIPT_RUNLEVEL = "5"

do_install:append() {
    # Create the init.d directory for startup scripts
	install -d ${D}${base_prefix}/etc/init.d

	# Install startup scripts into init.d
	install -m 0755 '${WORKDIR}/${STARTUP_SCRIPT_NAME}' '${D}${base_prefix}/etc/init.d/${STARTUP_SCRIPT_NAME}'
	install -m 0755 '${WORKDIR}/${EMMC_SCRIPT_NAME}' '${D}${base_prefix}/etc/init.d/${EMMC_SCRIPT_NAME}'
	install -m 0755 '${WORKDIR}/${CONTROLHOST_SCRIPT_NAME}' '${D}${base_prefix}/etc/init.d/${CONTROLHOST_SCRIPT_NAME}'
	install -m 0755 '${WORKDIR}/${SYSID_SCRIPT_NAME}' '${D}${base_prefix}/etc/init.d/${SYSID_SCRIPT_NAME}'
    install -m 0755 '${WORKDIR}/${ODIN_CONTROL_INSTANCES_MANAGER_SCRIPT_NAME}' '${D}${base_prefix}/etc/init.d/${ODIN_CONTROL_INSTANCES_MANAGER_SCRIPT_NAME}'
    
    # Set the scripts to run at startup by symlinking in to startup runlevel
    install -d ${D}${sysconfdir}/rc5.d
    install -d ${D}${sysconfdir}/rcS.d
    ln -sf ../init.d/${STARTUP_SCRIPT_NAME}  ${D}${sysconfdir}/rc${STARTUP_SCRIPT_RUNLEVEL}.d/S95${STARTUP_SCRIPT_NAME}
    ln -sf ../init.d/${EMMC_SCRIPT_NAME}  ${D}${sysconfdir}/rc${EMMC_SCRIPT_RUNLEVEL}.d/S80${EMMC_SCRIPT_NAME}
    ln -sf ../init.d/${CONTROLHOST_SCRIPT_NAME}  ${D}${sysconfdir}/rc${CONTROLHOST_SCRIPT_RUNLEVEL}.d/S90${CONTROLHOST_SCRIPT_NAME}
    ln -sf ../init.d/${SYSID_SCRIPT_NAME}  ${D}${sysconfdir}/rc${SYSID_SCRIPT_RUNLEVEL}.d/S85${SYSID_SCRIPT_NAME}
    ln -sf ../init.d/${ODIN_CONTROL_INSTANCES_MANAGER_SCRIPT_NAME}  ${D}${sysconfdir}/rc${ODIN_CONTROL_INSATNCES_MANAGER_SCRIPT_RUNLEVEL}.d/S97${ODIN_CONTROL_INSTANCES_MANAGER_SCRIPT_NAME}

    # Install default configuration files into conf.d with execute permissions
    install -d ${D}${base_prefix}/etc/conf.d/loki-config
    install -m 0644 '${WORKDIR}/${DEFAULT_CONFIG_NAME}' '${D}${base_prefix}/etc/conf.d/loki-config/${DEFAULT_CONFIG_NAME}'
    install -m 0644 '${WORKDIR}/${DEFAULT_INSTANCE_CONFIG_NAME}' '${D}${base_prefix}/etc/conf.d/loki-config/${DEFAULT_INSTANCE_CONFIG_NAME}'

    # Create an empty directory to stage LOKI image updates
    install -d ${D}${base_prefix}/opt/loki-update

    # Install script for starting odin-control instances
    install -d ${D}${base_prefix}/bin
    install -m 0755 '${WORKDIR}/${ODIN_CONTROL_INSTANCE_SCRIPT_NAME}' '${D}${base_prefix}/bin/${ODIN_CONTROL_INSTANCE_SCRIPT_NAME}'
}

# include the rootfs build directory locations in the yocto rootfs on exit
FILES:${PN} += "${base_prefix}/etc/init.d/*"
FILES:${PN} += "${base_prefix}/opt/loki-update/"
FILES:${PN} += "${base_prefix}/etc/conf.d/loki-config/*"
FILES:${PN} += "${base_prefix}/bin/${ODIN_CONTROL_INSTANCE_SCRIPT_NAME}"
