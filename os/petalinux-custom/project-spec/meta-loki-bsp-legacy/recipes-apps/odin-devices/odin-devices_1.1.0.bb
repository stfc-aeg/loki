SUMMARY = "This is a recipe to build odin-devices on PetaLinux"

# RDEPENDS specifies packages that are required at runtime on the host, as well as for build.
RDEPENDS_${PN} += "python3-setuptools"
RDEPENDS_${PN} += "odin-control"
RDEPENDS_${PN} += "python3-spidev"
RDEPENDS_${PN} += "python3-smbus"

SRC_URI = "git://git@github.com/stfc-aeg/odin-devices.git;protocol=ssh;tag=${PV}"

# This has to be in the format expected in Yocto's license list...
LICENSE = "CLOSED"

inherit setuptools3

S = "${WORKDIR}/git/"
