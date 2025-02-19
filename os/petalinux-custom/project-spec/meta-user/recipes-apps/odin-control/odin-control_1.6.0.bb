SUMMARY = "This is a recipe to build odin-control on PetaLinux"

# RDEPENDS specifies packages that are required at runtime on the host, as well as for build.
RDEPENDS:${PN} += "python3-setuptools"
RDEPENDS:${PN} += "python3-tornado (>=4.3)"
RDEPENDS:${PN} += "python3-fcntl"
RDEPENDS:${PN} += "python3-future"
RDEPENDS:${PN} += "python3-pyzmq (>=17.1.0)"
RDEPENDS:${PN} += "python3-psutil (>=5.0)"


# To build to a tag, update the tag here as well as the commit hash below.
# You can fetch the git hash with git ls-remote https://github.com/<repository> refs/tags/<tag>
GIT_TAG = "1.6.0"
GIT_HASH = "a5a399d21818405c262a1f09cdfe32a944e5f084"

PV = "${GIT_TAG}+git${SRCPV}"

# AUTOREV will just pull latest version
#SRCREV = "${AUTOREV}"
# SRCREV must now be the git hash of the target tag since Yocto does not like hanging references.
SRCREV = "${GIT_HASH}"

SRC_URI = "git://github.com/odin-detector/odin-control.git;protocol=http;branch=master"
SRC_URI[md5sum] = "1af5b49ffe84b3360b23086c7bb06a15"

# This has to be in the format expected in Yocto's license list...
LICENSE = "Apachev2"
# Get this value by running md5sum on the license file
LIC_FILES_CHKSUM = "file://LICENSE;md5=e3fc50a88d0a364313df4b21ef20c29e"


inherit setuptools3

S = "${WORKDIR}/git/"
