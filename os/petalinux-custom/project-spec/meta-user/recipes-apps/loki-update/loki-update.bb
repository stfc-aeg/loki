inherit odin-control-instance

SUMMARY = "A recipe for the Loki Update adapter"

HOMEPAGE = "https://github.com/stfc-aeg/loki-update"

RDEPENDS_${PN} += "odin-control (= 1.6.0)"
RDEPENDS_${PN} += "python3-pyfdt"

S = "${WORKDIR}/"

# Repo will be cloned into here
LOKI_UPDATE_REPO_CLONED_BASE = "git"

# Pull specific commit from repository
SRCREV = "e618b6cc110302181dbb606822cb349569bf762a"
PV = "0.0+git${SRCPV}"

REACT_UI_TAG = "v0.0.5"

# React UI will end up here
REACT_SOURCE_PATH = "loki-update-ui-${REACT_UI_TAG}"

SRC_URI = "git://git@github.com/stfc-aeg/loki-update.git;protocol=ssh;branch=main \
           https://github.com/stfc-aeg/loki-update/releases/download/${REACT_UI_TAG}/build.zip;subdir=${REACT_SOURCE_PATH};name=react-build-zip \
           "

# Checksum specifically for the react UI
SRC_URI[react-build-zip.sha256sum] = "da713185a13a89582de884091423b0b3ef0efa5e28a605ac8036d15246e9e739"

# Relative repository locations of standard resouces expected by the instance class
REPO_CONFIG_PATH = "${LOKI_UPDATE_REPO_CLONED_BASE}/test/config/loki-update.cfg"
REPO_STATIC_PATH = "${REACT_SOURCE_PATH}"

LICENSE = "CLOSED"

# Used to determine non-standard location of setup.py for setuptools
DISTUTILS_SETUP_PATH = "${LOKI_UPDATE_REPO_CLONED_BASE}"

FILES_${PN} += "${base_prefix}/opt/loki-detector/*"