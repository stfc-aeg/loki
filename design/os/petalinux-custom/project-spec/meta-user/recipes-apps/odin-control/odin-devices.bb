SUMMARY = "This is a recipe to build odin-devices on PetaLinux"

# RDEPENDS specifies packages that are required at runtime on the host, as well as for build.
RDEPENDS_${PN} += "python3-setuptools"
RDEPENDS_${PN} += "odin-control"

SRC_URI = "git://github.com/stfc-aeg/odin-devices.git"
# Automatically latest revision.
SRCREV = "${AUTOREV}"
PV = "1.0+git${SRCPV}"

# This has to be in the format expected in Yocto's license list...
LICENSE = "CLOSED"

inherit setuptools3

S = "${WORKDIR}/git/"
