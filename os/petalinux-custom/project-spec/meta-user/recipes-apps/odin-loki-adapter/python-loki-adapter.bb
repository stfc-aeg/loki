DESCRIPTION = "setuptools 3 project for installing a custom ODIN adapter for LOKI"
SECTION = "examples"
LICENSE = "CLOSED"

RDEPENDS:${PN} += "python3-setuptools"
RDEPENDS:${PN} += "odin-control (>=1.3.0)"
RDEPENDS:${PN} += "odin-devices (>=1.1.0)"

SRC_URI = "file://setup.py \
    file://loki/__init__.py \
    file://loki/adapter.py \
    file://loki/register_controller.py"

S = "${WORKDIR}"

inherit setuptools3
