SUMMARY = "This is a recipe to build odin-control on PetaLinux"

# RDEPENDS specifies packages that are required at runtime on the host, as well as for build.
RDEPENDS_${PN} += "python3-tornado (>=4.3)"
RDEPENDS_${PN} += "python3-setuptools"
RDEPENDS_${PN} += "python3-fcntl"

SRC_URI = "git://github.com/odin-detector/odin-control.git \
		file://fix-non-required-dependencies.patch"
SRCREV = "1.0.0"

# This has to be in the format expected in Yocto's license list...
LICENSE = "Apachev2"
# Get this value by running md5sum on the license file
LIC_FILES_CHKSUM = "file://LICENSE;md5=e3fc50a88d0a364313df4b21ef20c29e"

inherit setuptools3

S = "${WORKDIR}/git/"
