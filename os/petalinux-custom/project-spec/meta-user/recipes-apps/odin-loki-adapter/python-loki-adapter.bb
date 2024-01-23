DESCRIPTION = "setuptools 3 project for installing a custom ODIN adapter for LOKI"
SECTION = "examples"
LICENSE = "CLOSED"

RDEPENDS_${PN} += "python3-setuptools"
RDEPENDS_${PN} += "odin-control (= 1.3.0)"
RDEPENDS_${PN} += "odin-devices (=1.1.0)"

SRC_URI = "file://setup.py \
    file://loki/__init__.py \
    file://loki/adapter.py"

S = "${WORKDIR}"

inherit setuptools3

#do_install_append () {
#    install -d ${D}${bindir}
#    install -m 0755 lokiadapter/loki-adapter.py ${D}${bindir}
#}
