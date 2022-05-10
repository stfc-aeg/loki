SUMMARY = "Creates an unpriviledged user loki for detector software execution with limited access to peripherals"

inherit useradd

LICENSE = "CLOSED"

LOKI_USERNAME = "loki"

USERADD_PACKAGES = "${PN}"

USERADD_PARAM_${PN} = "-d /home/${LOKI_USERNAME} -r -s /bin/bash ${LOKI_USERNAME}"
GROUPADD_PARAM_${PN} = "-r gpiod; -r spiuser; -r smbususer"
GROUPMEMS_PARAM_${PN} = "--group gpiod --add ${LOKI_USERNAME}; \
                            --group spiuser --add ${LOKI_USERNAME}; \
                            --group smbususer --add ${LOKI_USERNAME}"

do_install_append() {
    # Allow loki to operate all GPIO lines
    install -d '${D}${base_prefix}/etc/udev/rules.d'
    echo -e 'SUBSYSTEM=="gpio", KERNEL=="gpiochip*", GROUP="gpiod", MODE="0660"\n' >> '${D}${base_prefix}/etc/udev/rules.d/10-gpiod.rules'

    # Allow loki to operate all spidev devices
    echo -e 'KERNEL=="spidev*", GROUP="spiuser", MODE="0660"' >> '${D}${base_prefix}/etc/udev/rules.d/10-spidev.rules'

    # Allow loki to operate all smbus (i2c) devices
    echo -e 'KERNEL=="i2c*", GROUP="smbususer", MODE="0660"' >> '${D}${base_prefix}/etc/udev/rules.d/10-smbus.rules'
}

# include the rootfs build directory locations in the yocto rootfs on exit
FILES_${PN} += "${base_prefix}/etc/udev/rules.d/*"
