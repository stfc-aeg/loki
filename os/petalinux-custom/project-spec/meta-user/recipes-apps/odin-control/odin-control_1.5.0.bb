SUMMARY = "This is a recipe to build odin-control on PetaLinux"

# RDEPENDS specifies packages that are required at runtime on the host, as well as for build.
RDEPENDS_${PN} += "python3-setuptools"
#RDEPENDS_${PN} += "python3-tornado (>=4.3)"
RDEPENDS_${PN} += "python3-tornado (<6.0)"
RDEPENDS_${PN} += "python3-fcntl"
RDEPENDS_${PN} += "python3-future"
RDEPENDS_${PN} += "python3-pyzmq (>=17.0)"
RDEPENDS_${PN} += "python3-psutil"

#SRC_URI = "git://git@github.com/odin-detector/odin-control.git;protocol=ssh;tag=${PV}"
#SRC_URI[md5sum] = "1af5b49ffe84b3360b23086c7bb06a15"

# SRCREV is the git tag, defined by the filename package version (wildcard)
SRC_URI = "git://github.com/stfc-aeg/odin-control.git;protocol=http;branch=clean_shutdown"
SRC_URI[md5sum] = "d16e2fbaebeebf11d435c7b879104f68"
SRCREV = "338f9e590ffad75dbd3217d03d3fbb130e0ee0c3"

# This has to be in the format expected in Yocto's license list...
LICENSE = "Apachev2"
# Get this value by running md5sum on the license file
LIC_FILES_CHKSUM = "file://LICENSE;md5=e3fc50a88d0a364313df4b21ef20c29e"


inherit setuptools3

S = "${WORKDIR}/git/"
