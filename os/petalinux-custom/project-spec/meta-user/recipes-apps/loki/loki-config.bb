SUMMARY = "Installer for generic LOKI setup script, which facilitates the configuration of a non-volatile debug setup."

RDEPENDS:${PN} += "loki-config"

# Repo URL.
SRC_URI = " \
    file://services \
    file://loki-system-config-default.conf \
    file://instance-config-default.conf \
    file://odin-control-instance.sh \
    "

# This has to be in the format expected in Yocto's license list...
LICENSE = "CLOSED"

DEFAULT_CONFIG_NAME = "loki-system-config-default.conf"
DEFAULT_INSTANCE_CONFIG_NAME = "instance-config-default.conf"

# General LOKI startup script for odin-control
STARTUP_SCRIPT_NAME = "loki-config.sh"
STARTUP_SERVICE_NAME = "loki-config.service"

# Start-up script to format the eMMC on first carrier boot, or if the partition is deleted
EMMC_SCRIPT_NAME = "loki-bootstrap-emmc.sh"
EMMC_SERVICE_NAME = "loki-bootstrap-emmc.service"

# Start-up script to initialise a connection to a control host PC, mounting relevant
CONTROLHOST_SCRIPT_NAME = "loki-connect-control-host.sh"
CONTROLHOST_SERVICE_NAME = "loki-connect-control-host.service"

# Start-up script to determine the board-unique System ID, and store it in /etc/loki/system-id
SYSID_SCRIPT_NAME = "loki-get-system-id.sh"
SYSID_SERVICE_NAME = "loki-get-system-id.service"

# Script to start odin-control instances
ODIN_CONTROL_INSTANCE_SCRIPT_NAME = "odin-control-instance.sh"

# odin-control instances manager init script
ODIN_CONTROL_INSTANCES_MANAGER_SCRIPT_NAME = "odin-control-instances-manager.sh"
ODIN_CONTROL_INSTANCES_MANAGER_SERVICE_NAME = "odin-control-instances-manager.service"

SYSTEMD_SCRIPT_DESTINATION = "/etc/systemd/system/"
BOOT_SCRIPT_DESTINATION = "/opt/loki-service-scripts/"

do_install:append() {
	install -d ${D}${base_prefix}/${SYSTEMD_SCRIPT_DESTINATION}
	install -d ${D}${base_prefix}/${BOOT_SCRIPT_DESTINATION}

	# Install startup scripts as systemd service unit files
	install -m 0755 '${WORKDIR}/services/${STARTUP_SCRIPT_NAME}' '${D}${base_prefix}/${BOOT_SCRIPT_DESTINATION}/${STARTUP_SCRIPT_NAME}'
	install -m 0755 '${WORKDIR}/services/${STARTUP_SERVICE_NAME}' '${D}${base_prefix}/${SYSTEMD_SCRIPT_DESTINATION}/${STARTUP_SERVICE_NAME}'
	install -m 0755 '${WORKDIR}/services/${EMMC_SCRIPT_NAME}' '${D}${base_prefix}/${BOOT_SCRIPT_DESTINATION}/${EMMC_SCRIPT_NAME}'
	install -m 0755 '${WORKDIR}/services/${EMMC_SERVICE_NAME}' '${D}${base_prefix}/${SYSTEMD_SCRIPT_DESTINATION}/${EMMC_SERVICE_NAME}'
	install -m 0755 '${WORKDIR}/services/${CONTROLHOST_SCRIPT_NAME}' '${D}${base_prefix}/${BOOT_SCRIPT_DESTINATION}/${CONTROLHOST_SCRIPT_NAME}'
	install -m 0755 '${WORKDIR}/services/${CONTROLHOST_SERVICE_NAME}' '${D}${base_prefix}/${SYSTEMD_SCRIPT_DESTINATION}/${CONTROLHOST_SERVICE_NAME}'
	install -m 0755 '${WORKDIR}/services/${SYSID_SCRIPT_NAME}' '${D}${base_prefix}/${BOOT_SCRIPT_DESTINATION}/${SYSID_SCRIPT_NAME}'
	install -m 0755 '${WORKDIR}/services/${SYSID_SERVICE_NAME}' '${D}${base_prefix}/${SYSTEMD_SCRIPT_DESTINATION}/${SYSID_SERVICE_NAME}'
	install -m 0755 '${WORKDIR}/services/${ODIN_CONTROL_INSTANCES_MANAGER_SCRIPT_NAME}' '${D}${base_prefix}/${BOOT_SCRIPT_DESTINATION}/${ODIN_CONTROL_INSTANCES_MANAGER_SCRIPT_NAME}'
	install -m 0755 '${WORKDIR}/services/${ODIN_CONTROL_INSTANCES_MANAGER_SERVICE_NAME}' '${D}${base_prefix}/${SYSTEMD_SCRIPT_DESTINATION}/${ODIN_CONTROL_INSTANCES_MANAGER_SERVICE_NAME}'
 
    # If a script is linked into the wants directory, it will be started at boot. Usually this is
    # handled by 'systemctl enable'.
    install -d ${D}${base_prefix}/etc/systemd/system/multi-user.target.wants/
    ln -sf ${SYSTEMD_SCRIPT_DESTINATION}/${STARTUP_SERVICE_NAME}  ${D}/${base_prefix}//etc/systemd/system/multi-user.target.wants/${STARTUP_SERVICE_NAME}
    ln -sf ${SYSTEMD_SCRIPT_DESTINATION}/${EMMC_SERVICE_NAME}  ${D}/${base_prefix}//etc/systemd/system/multi-user.target.wants/${EMMC_SERVICE_NAME}
    ln -sf ${SYSTEMD_SCRIPT_DESTINATION}/${CONTROLHOST_SERVICE_NAME}  ${D}/${base_prefix}//etc/systemd/system/multi-user.target.wants/${CONTROLHOST_SERVICE_NAME}
    ln -sf ${SYSTEMD_SCRIPT_DESTINATION}/${SYSID_SERVICE_NAME}  ${D}/${base_prefix}//etc/systemd/system/multi-user.target.wants/${SYSID_SERVICE_NAME}
    ln -sf ${SYSTEMD_SCRIPT_DESTINATION}/${ODIN_CONTROL_INSTANCES_MANAGER_SERVICE_NAME}  ${D}/${base_prefix}//etc/systemd/system/multi-user.target.wants/${ODIN_CONTROL_INSTANCES_MANAGER_SERVICE_NAME}

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
FILES:${PN} += "${base_prefix}/opt/loki-update/"
FILES:${PN} += "${base_prefix}/etc/conf.d/loki-config/*"
FILES:${PN} += "${base_prefix}/bin/${ODIN_CONTROL_INSTANCE_SCRIPT_NAME}"
FILES:${PN} += "${base_prefix}${BOOT_SCRIPT_DESTINATION}/*"
FILES:${PN} += "${base_prefix}${SYSTEMD_SCRIPT_DESTINATION}/*"
FILES:${PN} += "${base_prefix}${SYSTEMD_SCRIPT_DESTINATION}/*"
FILES:${PN} += "${base_prefix}/etc/systemd/system/multi-user.target.wants/*"
