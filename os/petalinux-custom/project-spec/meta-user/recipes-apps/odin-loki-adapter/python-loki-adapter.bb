DESCRIPTION = "setuptools 3 project for installing a custom ODIN adapter for LOKI"
SECTION = "examples"
LICENSE = "CLOSED"

RDEPENDS_${PN} += "python3-setuptools"
RDEPENDS_${PN} += "odin-control (>=1.3.0)"
RDEPENDS_${PN} += "odin-devices (>=1.1.0)"

SRC_URI = "file://setup.py \
    file://loki/__init__.py \
    file://loki/adapter.py \
    file://loki/register_controller.py"

S = "${WORKDIR}"

inherit setuptools3
