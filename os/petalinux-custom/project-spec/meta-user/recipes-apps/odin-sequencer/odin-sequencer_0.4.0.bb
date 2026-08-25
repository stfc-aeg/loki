SUMMARY = "This is a recipe to build odin-sequencer on PetaLinux"

# RDEPENDS specifies packages that are required at runtime on the host, as well as for build.
RDEPENDS:${PN} += "python3-odin-control (>=2.0.0)"
RDEPENDS:${PN} += "python3-inotify"

DEPENDS += " \
    python3-setuptools-scm-native \
    python3-toml-native \
"
inherit python_setuptools_build_meta

# To build to a tag, update the tag here as well as the commit hash below.
# You can fetch the git hash with git ls-remote https://github.com/<repository> refs/tags/<tag>
GIT_TAG = "0.4.0"
GIT_HASH = "6f4e10ce1e4af376a67fcbfb49f2eba44e69076b"

PV = "${GIT_TAG}+git${SRCPV}"

SRCREV = "${GIT_HASH}"

SRC_URI = "git://github.com/stfc-aeg/odin-sequencer.git;protocol=http;branch=main"

# This has to be in the format expected in Yocto's license list...
LICENSE = "Apache-2.0"
# Get this value by running md5sum on the license file
LIC_FILES_CHKSUM = "file://LICENSE;md5=2bd339c7a9cf03feeeee2f768a4eb0ce"


S = "${WORKDIR}/git"
