SUMMARY = "This is a recipe to build odin-devices on PetaLinux"

# RDEPENDS specifies packages that are required at runtime on the host, as well as for build.
RDEPENDS:${PN} += "python3-setuptools"
RDEPENDS:${PN} += "odin-control"
RDEPENDS:${PN} += "python3-spidev"
RDEPENDS:${PN} += "python3-smbus"

SRC_URI = "git://git@github.com/stfc-aeg/odin-devices.git;protocol=ssh;tag=${PV}"

# Set revision to commit hash. Update manually when satisfied with compatibility
#SRCREV = "5332440d9bb9a33dbd254b2c8ba35e5120097a0e"
#PV = "1.0+git${SRCPV}"

# This has to be in the format expected in Yocto's license list...
LICENSE = "CLOSED"

inherit setuptools3

S = "${WORKDIR}/git"
