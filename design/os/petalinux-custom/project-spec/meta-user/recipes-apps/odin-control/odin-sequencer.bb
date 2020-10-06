SUMMARY = "This is a recipe to build odin-sequencer on PetaLinux"

# RDEPENDS specifies packages that are required at runtime on the host, as well as for build.
RDEPENDS_${PN} += "odin-control"
# python-test should only be required for odin-sequencer development, not usage.
#RDEPENDS_${PN} += "python3-pytest (>=3)"
#RDEPENDS_${PN} += "python3-pytest-runner"
RDEPENDS_${PN} += "python3-inotify"

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
