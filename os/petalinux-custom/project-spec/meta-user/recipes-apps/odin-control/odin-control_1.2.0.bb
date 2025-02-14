SUMMARY = "This is a recipe to build odin-control on PetaLinux"

# RDEPENDS specifies packages that are required at runtime on the host, as well as for build.
RDEPENDS:${PN} += "python3-setuptools"
RDEPENDS:${PN} += "python3-tornado (<6.0)"
RDEPENDS:${PN} += "python3-fcntl"
RDEPENDS:${PN} += "python3-future"
RDEPENDS:${PN} += "python3-pyzmq (>=17.0)"
RDEPENDS:${PN} += "python3-psutil"

SRC_URI = "git://git@github.com/odin-detector/odin-control.git;protocol=ssh;tag=${PV}"
SRC_URI[md5sum] = "1af5b49ffe84b3360b23086c7bb06a15"

# SRCREV is the git tag, defined by the filename package version (wildcard)
#SRCREV = ${PV}

# This has to be in the format expected in Yocto's license list...
LICENSE = "Apachev2"
# Get this value by running md5sum on the license file
LIC_FILES_CHKSUM = "file://LICENSE;md5=e3fc50a88d0a364313df4b21ef20c29e"


inherit setuptools3

S = "${WORKDIR}/git/"
