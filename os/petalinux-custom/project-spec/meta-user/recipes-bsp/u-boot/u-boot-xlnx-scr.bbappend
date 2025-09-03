FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI += "file://boot.cmd.default.initrd \
	file://boot.cmd.default"

BOOTMODE = "default"
BOOTFILE_EXT = ".initrd"
