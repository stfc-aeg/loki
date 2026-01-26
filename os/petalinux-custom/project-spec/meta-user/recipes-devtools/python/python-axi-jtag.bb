SUMMARY = "Python UIO drivers for the debug bridge IP"
DESCRIPTION = "Python UIO drivers for JTAG"
LICENSE = "CLOSED"

FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

RDEPENDS_${PN} += " py-uio"

SRC_URI = " \
    file://setup.py \
    file://axi_jtag/ \
    "
S = "${WORKDIR}/"

inherit setuptools3
