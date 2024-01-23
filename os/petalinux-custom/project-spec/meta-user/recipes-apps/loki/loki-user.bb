SUMMARY = "Creates an unpriviledged user loki for detector software execution with limited access to peripherals"

inherit useradd

LICENSE = "CLOSED"

SRC_URI = "file://lokiinfo/application-version \
    file://lokiinfo/application-name \
    file://lokiinfo/platform \
    file://lokiinfo/version \
    "

# Ensure that if any recipe intends to include this directory that it has DEPENDS += "loki-user".
LOKI_INSTALL_DIRECTORY = "/opt/loki-detector/"
SYSROOT_DIRS += "${LOKI_INSTALL_DIRECTORY}"

LOKI_USERNAME = "loki"

# Encrypted form of password created with openssl passwd. Note: $ signs must be escaped.
LOKI_PASS_ENC = '\$1\$egoKrtB7\$.UUBtRsxiasoHU1W.4NYV/'

USERADD_PACKAGES = "${PN}"

# Note: single quotes around LOKI_PASS_ENC are crucial
USERADD_PARAM_${PN} = "-p '${LOKI_PASS_ENC}' -m -d /home/${LOKI_USERNAME} -r -s /bin/bash ${LOKI_USERNAME}"
GROUPADD_PARAM_${PN} = "-r gpiod; -r spiuser; -r smbususer"
GROUPMEMS_PARAM_${PN} = "--group gpiod --add ${LOKI_USERNAME}; \
                            --group spiuser --add ${LOKI_USERNAME}; \
                            --group smbususer --add ${LOKI_USERNAME}"

do_install_append() {
    # Create  detector operational directory so that loki can execute from it
    install -d ${D}${base_prefix}${LOKI_INSTALL_DIRECTORY}

    # Create a directory that may be written to by the loki user in case of file exports
    install -d ${D}${base_prefix}${LOKI_INSTALL_DIRECTORY}/exports
    chown -R ${LOKI_USERNAME} '${D}${base_prefix}${LOKI_INSTALL_DIRECTORY}/exports'

    # Allow loki to operate all GPIO lines
    install -d '${D}${base_prefix}/etc/udev/rules.d'
    echo -e 'SUBSYSTEM=="gpio", KERNEL=="gpiochip*", GROUP="gpiod", MODE="0660"\n' >> '${D}${base_prefix}/etc/udev/rules.d/10-gpiod.rules'

    # Allow loki to operate all spidev devices
    echo -e 'KERNEL=="spidev*", GROUP="spiuser", MODE="0660"' >> '${D}${base_prefix}/etc/udev/rules.d/10-spidev.rules'

    # Allow loki to operate all smbus (i2c) devices
    echo -e 'KERNEL=="i2c-*", GROUP="smbususer", MODE="0660"' >> '${D}${base_prefix}/etc/udev/rules.d/10-smbus.rules'

    # Install a new 'loki' directory in /etc/ that will contain information about the installation for introspection
    # Applications should .bbappend this to install additional information into the directory
    install -d ${D}${base_prefix}/etc/loki
	install -m 0755 '${WORKDIR}/lokiinfo/version' '${D}${base_prefix}/etc/loki/version'
	install -m 0755 '${WORKDIR}/lokiinfo/platform' '${D}${base_prefix}/etc/loki/platform'
	install -m 0755 '${WORKDIR}/lokiinfo/application-name' '${D}${base_prefix}/etc/loki/application-name'
	install -m 0755 '${WORKDIR}/lokiinfo/application-version' '${D}${base_prefix}/etc/loki/application-version'
}

# include the rootfs build directory locations in the yocto rootfs on exit
FILES_${PN} += "${base_prefix}${LOKI_INSTALL_DIRECTORY}"
FILES_${PN} += "${base_prefix}/etc/loki"
FILES_${PN} += "${base_prefix}/etc/udev/rules.d/*"
