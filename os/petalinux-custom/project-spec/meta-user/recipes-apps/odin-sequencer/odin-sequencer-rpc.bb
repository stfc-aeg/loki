SUMMARY = "Recipe to build odin-sequencer rpc package alongside odin-sequencer"

# Ideally this should be tightly coupled to the odin-sequencer version, as they pull the same repo.
RDEPENDS:${PN} += "odin-sequencer"

# Manuall specify the python dependencies, since these seem not to be brought in from the TOML
RDEPENDS:${PN} += " python3-pyzmq"
#RDEPENDS:${PN} += " python3-pydantic (>= 2.0.0)"
#RDEPENDS:${PN} += " python3-backports-strenum (< 2.0.0)"

GIT_TAG = "0.2.0"
GIT_HASH = "6ff07b46fb4bb1d182a0460e4c9478328292f329"

PV = "${GIT_TAG}+git${SRCPV}"
SRCREV = "${GIT_HASH}"

# This should be EXACTLY the same as odin-sequencer
SRC_URI = "git://github.com/stfc-aeg/odin-sequencer.git;protocol=http;branch=jupyter_rpc"

DEPENDS += " ${PYTHON_PN}-setuptools-scm-native"

LICENSE = "Apachev2"
# The license is at the top level of the repo, not the setup path
LIC_FILES_CHKSUM = "file://${WORKDIR}/git/LICENSE;md5=2bd339c7a9cf03feeeee2f768a4eb0ce"

# Build using scm pyproject.toml via poetry
inherit python_poetry_core
#inherit setuptools3

# This installs the rpc package in the same repo as odin-sequencer in its own directory
S = "${WORKDIR}/git/rpc"
