SUMMARY = "This is a recipe to build odin-sequencer on PetaLinux"

# RDEPENDS specifies packages that are required at runtime on the host, as well as for build.
RDEPENDS_${PN} += "odin-control"
RDEPENDS_${PN} += "python3-inotify"

SRC_URI = "git://git@github.com/stfc-aeg/odin-sequencer.git;protocol=http;tag=${PV} \
		file://odin-sequencer-remove-inotify-setuptools.patch"

# This has to be in the format expected in Yocto's license list...
LICENSE = "Apachev2"
# Get this value by running md5sum on the license file
LIC_FILES_CHKSUM = "file://LICENSE;md5=2bd339c7a9cf03feeeee2f768a4eb0ce"

inherit setuptools3

do_configure_prepend() {
	bbdebug 2 "Current working directory (pwd):" ${pwd}
	bbdebug 2 "Build Directory:" ${B}
	bbdebug 2 "WORKDIR Directory:" ${WORKDIR}
	bbdebug 2 "Source Directory:" ${S}
}

S = "${WORKDIR}/git/"
