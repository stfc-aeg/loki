SUMMARY = "Installer for generic LOKI setup script, which facilitates the configuration of a non-volatile debug setup."

RDEPENDS_${PN} += "loki-config"

# Repo URL.
SRC_URI = "file://loki-config.sh \
    file://auto-format-emmc.sh \
    file://config-default.conf \
    "

# This has to be in the format expected in Yocto's license list...
LICENSE = "CLOSED"

DEFAULT_CONFIG_NAME = "config-default.conf"

STARTUP_SCRIPT_NAME = "loki-config.sh"
STARTUP_SCRIPT_RUNLEVEL = "5"

EMMC_SCRIPT_NAME = "auto-format-emmc.sh"
EMMC_SCRIPT_RUNLEVEL = "5"

do_install_append() {
    # Create the init.d directory for startup scripts
	install -d ${D}${base_prefix}/etc/init.d

	# Install odin_server startup script into init.d
	install -m 0755 '${WORKDIR}/${STARTUP_SCRIPT_NAME}' '${D}${base_prefix}/etc/init.d/${STARTUP_SCRIPT_NAME}'

    # Install the emmc formatting script into init.d
	install -m 0755 '${WORKDIR}/${EMMC_SCRIPT_NAME}' '${D}${base_prefix}/etc/init.d/${EMMC_SCRIPT_NAME}'

    # Set the scripts to run at startup by symlinking in to startup runlevel
    install -d ${D}${sysconfdir}/rc${STARTUP_SCRIPT_RUNLEVEL}.d
    ln -sf ../init.d/${STARTUP_SCRIPT_NAME}  ${D}${sysconfdir}/rc${STARTUP_SCRIPT_RUNLEVEL}.d/S90${STARTUP_SCRIPT_NAME}
    ln -sf ../init.d/${EMMC_SCRIPT_NAME}  ${D}${sysconfdir}/rc${EMMC_SCRIPT_RUNLEVEL}.d/S90${EMMC_SCRIPT_NAME}

    # Install default configuration file into conf.d with execute permissions
    install -d ${D}${base_prefix}/etc/conf.d/loki-config
    install -m 0644 '${WORKDIR}/${DEFAULT_CONFIG_NAME}' '${D}${base_prefix}/etc/conf.d/loki-config/${DEFAULT_CONFIG_NAME}'

}

# include the rootfs build directory locations in the yocto rootfs on exit
FILES_${PN} += "${base_prefix}/etc/init.d/*"
FILES_${PN} += "${base_prefix}/etc/conf.d/loki-config/*"
