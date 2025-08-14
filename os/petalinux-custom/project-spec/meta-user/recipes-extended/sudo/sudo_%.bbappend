FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI:append := " \
    file://99-loki-sudo \
    "

do_install:append() {
    # Create a sudoers file for loki user, allowing certain commands
    install -d '${D}${base_prefix}/etc/sudoers.d'
	install -m 0755 '${WORKDIR}/99-loki-sudo' '${D}${base_prefix}/etc/sudoers.d/99-loki-sudo'
}

FILES:${PN} += "${base_prefix}/etc/sudoers.d/99-loki-sudo"
