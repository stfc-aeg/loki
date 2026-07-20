SUMMARY = "This is a recipe to build odin-sequencer on PetaLinux"

# RDEPENDS specifies packages that are required at runtime on the host, as well as for build.
RDEPENDS:${PN} += "odin-control"
RDEPENDS:${PN} += "python3-inotify"

DEPENDS += " ${PYTHON_PN}-setuptools-scm-native"
#RRECOMMENDS:${PN} = " odin-sequencer-rpc"

# To build to a tag, update the tag here as well as the commit hash below.
# You can fetch the git hash with git ls-remote https://github.com/<repository> refs/tags/<tag>
# If you're not building to a tag, you must still put some version here, in doubt the last tag or 0.0.0
GIT_TAG = "0.2.0"
GIT_HASH = "e0b1b08ea8b4ad306b60c5c9ab837609527bf571"

PV = "${GIT_TAG}+git${SRCPV}"

# AUTOREV will just pull latest version
#SRCREV = "${AUTOREV}"
# SRCREV must now be the git hash of the target tag since Yocto does not like hanging references.
SRCREV = "${GIT_HASH}"

SRC_URI = "git://github.com/stfc-aeg/odin-sequencer.git;protocol=http;branch=jupyter_rpc"

# This has to be in the format expected in Yocto's license list...
LICENSE = "Apachev2"
# Get this value by running md5sum on the license file
LIC_FILES_CHKSUM = "file://LICENSE;md5=2bd339c7a9cf03feeeee2f768a4eb0ce"

#inherit setuptools3
inherit python_poetry_core

do_configure:prepend() {
	bbdebug 2 "Current working directory (pwd):" ${pwd}
	bbdebug 2 "Build Directory:" ${B}
	bbdebug 2 "WORKDIR Directory:" ${WORKDIR}
	bbdebug 2 "Source Directory:" ${S}
}

S = "${WORKDIR}/git"
