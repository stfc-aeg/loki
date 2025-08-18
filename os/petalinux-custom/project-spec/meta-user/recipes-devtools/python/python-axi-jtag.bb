SUMMARY = "Python UIO drivers for the debug bridge IP"
DESCRIPTION = "Python UIO drivers for JTAG"
LICENSE = "CLOSED"

RDEPENDS_${PN} += " py-uio"

SRC_URI = " \
    file://python-axi-jtag \
    "
S = "${WORKDIR}/"

inherit setuptools3