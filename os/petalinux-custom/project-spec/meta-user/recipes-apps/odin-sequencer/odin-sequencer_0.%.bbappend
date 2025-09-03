GIT_HASH = "5331bf846669c1f4b88c5dd35e9911835cc40f99"
SRCREV = "${GIT_HASH}"

SRC_URI = "git://github.com/stfc-aeg/odin-sequencer.git;protocol=http;branch=jupyter_rpc"

DEPENDS += " ${PYTHON_PN}-setuptools-scm-native"
