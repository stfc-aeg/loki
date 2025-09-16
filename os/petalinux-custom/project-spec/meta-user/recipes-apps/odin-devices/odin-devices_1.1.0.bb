SUMMARY = "This is a recipe to build odin-devices on PetaLinux"

# RDEPENDS specifies packages that are required at runtime on the host, as well as for build.
RDEPENDS:${PN} += "python3-setuptools"
RDEPENDS:${PN} += "odin-control"
RDEPENDS:${PN} += "python3-spidev"
RDEPENDS:${PN} += "python3-smbus2"

SRC_URI = "git://github.com/stfc-aeg/odin-devices.git;protocol=http;tag=${PV}"

# This has to be in the format expected in Yocto's license list...
LICENSE = "CLOSED"

inherit setuptools3

S = "${WORKDIR}/git"
