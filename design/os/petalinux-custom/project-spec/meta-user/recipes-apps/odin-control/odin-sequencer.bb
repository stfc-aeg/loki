SUMMARY = "This is a recipe to build odin-sequencer on PetaLinux"

# RDEPENDS specifies packages that are required at runtime on the host, as well as for build.
RDEPENDS_${PN} += "python3-setuptools"
RDEPENDS_${PN} += "odin-control"
RDEPENDS_${PN} += "python3-pytest (>=3)"
RDEPENDS_${PN} += "python3-pytest-runner"
RDEPENDS_${PN} += "inotify"
#RDEPENDS_${PN} += "python3-pyinotify"
#RDEDPENDS_${PN} += "inotify-tools"

SRC_URI = "git://github.com/stfc-aeg/odin-sequencer.git \
		file://odin-sequencer-remove-inotify-setuptools.patch"
# Automatically latest revision.
SRCREV = "${AUTOREV}"
PV = "1.0+git${SRCPV}"

# This has to be in the format expected in Yocto's license list...
LICENSE = "Apachev2"
# Get this value by running md5sum on the license file
LIC_FILES_CHKSUM = "file://LICENSE;md5=2bd339c7a9cf03feeeee2f768a4eb0ce"

inherit setuptools3

S = "${WORKDIR}/git/"
