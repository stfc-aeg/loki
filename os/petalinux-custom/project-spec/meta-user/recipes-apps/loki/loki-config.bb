SUMMARY = "Installer for generic LOKI setup script, which facilitates the configuration of a non-volatile debug setup."

RDEPENDS_${PN} += "loki-config"

# Repo URL.
SRC_URI = "file://loki-config.sh \
    file://auto-format-emmc.sh \
    file://loki-connect-control-host.sh \
    file://loki-get-system-id.sh \
    file://loki-aliases.sh \
    file://config-default.conf \
    "

# This has to be in the format expected in Yocto's license list...
LICENSE = "CLOSED"

DEFAULT_CONFIG_NAME = "config-default.conf"

# General LOKI startup script for odin-control
STARTUP_SCRIPT_NAME = "loki-config.sh"
STARTUP_SCRIPT_RUNLEVEL = "5"

# Start-up script to format the eMMC on first carrier boot, or if the partition is deleted
EMMC_SCRIPT_NAME = "auto-format-emmc.sh"
EMMC_SCRIPT_RUNLEVEL = "5"

# Start-up script to initialise a connection to a control host PC, mounting relevant
CONTROLHOST_SCRIPT_NAME = "loki-connect-control-host.sh"
CONTROLHOST_SCRIPT_RUNLEVEL = "5"

# Start-up script to determine the board-unique System ID, and store it in /etc/loki/system-id
SYSID_SCRIPT_NAME = "loki-get-system-id.sh"
SYSID_SCRIPT_RUNLEVEL = "5"

do_install_append() {
    # Create the init.d directory for startup scripts
	install -d ${D}${base_prefix}/etc/init.d

	# Install startup scripts into init.d
	install -m 0755 '${WORKDIR}/${STARTUP_SCRIPT_NAME}' '${D}${base_prefix}/etc/init.d/${STARTUP_SCRIPT_NAME}'
	install -m 0755 '${WORKDIR}/${EMMC_SCRIPT_NAME}' '${D}${base_prefix}/etc/init.d/${EMMC_SCRIPT_NAME}'
	install -m 0755 '${WORKDIR}/${CONTROLHOST_SCRIPT_NAME}' '${D}${base_prefix}/etc/init.d/${CONTROLHOST_SCRIPT_NAME}'
	install -m 0755 '${WORKDIR}/${SYSID_SCRIPT_NAME}' '${D}${base_prefix}/etc/init.d/${SYSID_SCRIPT_NAME}'

    # Set the scripts to run at startup by symlinking in to startup runlevel
    install -d ${D}${sysconfdir}/rc${STARTUP_SCRIPT_RUNLEVEL}.d
    ln -sf ../init.d/${STARTUP_SCRIPT_NAME}  ${D}${sysconfdir}/rc${STARTUP_SCRIPT_RUNLEVEL}.d/S95${STARTUP_SCRIPT_NAME}
    ln -sf ../init.d/${EMMC_SCRIPT_NAME}  ${D}${sysconfdir}/rc${EMMC_SCRIPT_RUNLEVEL}.d/S80${EMMC_SCRIPT_NAME}
    ln -sf ../init.d/${CONTROLHOST_SCRIPT_NAME}  ${D}${sysconfdir}/rc${CONTROLHOST_SCRIPT_RUNLEVEL}.d/S90${CONTROLHOST_SCRIPT_NAME}
    ln -sf ../init.d/${SYSID_SCRIPT_NAME}  ${D}${sysconfdir}/rc${SYSID_SCRIPT_RUNLEVEL}.d/S85${SYSID_SCRIPT_NAME}

    # Install default configuration file into conf.d with execute permissions
    install -d ${D}${base_prefix}/etc/conf.d/loki-config
    install -m 0644 '${WORKDIR}/${DEFAULT_CONFIG_NAME}' '${D}${base_prefix}/etc/conf.d/loki-config/${DEFAULT_CONFIG_NAME}'

    # Create an empty directory to stage LOKI image updates
    install -d ${D}${base_prefix}/opt/loki-update

    # Create a directory for system commands to be sourced automatically
    install -d ${D}${base_prefix}/etc/profile.d/
	install -m 0755 '${WORKDIR}/loki-aliases.sh' '${D}${base_prefix}/etc/profile.d/loki-aliases.sh'
}

# include the rootfs build directory locations in the yocto rootfs on exit
FILES_${PN} += "${base_prefix}/etc/init.d/*"
FILES_${PN} += "${base_prefix}/opt/loki-update/"
FILES_${PN} += "${base_prefix}/etc/profile.d/*"
FILES_${PN} += "${base_prefix}/etc/conf.d/loki-config/*"
