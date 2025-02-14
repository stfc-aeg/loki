# Replace the normal interfaces file with my custom one
FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

do_install:append() {
	# Create a directory where additional configurations bind-mounted from eMMC will be
	# Bind mounting takes place in fstab, see base-files recipe
	install -d ${D}${base_prefix}/etc/network/interfaces-mmc
}

FILES:${PN} += "${base_prefix}/etc/network/interfaces-mmc"
