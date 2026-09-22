SUMMARY = "A recipe for the Loki Update adapter"

HOMEPAGE = "https://github.com/stfc-aeg/loki-update"

RDEPENDS:${PN} += "python3-odin-control (>=2.0.0)"
RDEPENDS:${PN} += "python3-pyfdt"

# Repo will be cloned into here
LOKI_UPDATE_REPO_CLONED_BASE = "git"

# Pull specific commit from repository
SRCREV = "9bab544a565def711b8e71d5d4de3084c80a7fc6"
PV = "0.0+git${SRCPV}"

SRC_URI = "git://github.com/stfc-aeg/loki-update.git;protocol=http;branch=odin-control-2.0-update"

inherit setuptools3

do_configure:prepend() {
	cd ${WORKDIR}/${LOKI_UPDATE_REPO_CLONED_BASE}
}

do_compile:prepend() {
	cd ${WORKDIR}/${LOKI_UPDATE_REPO_CLONED_BASE}
}

do_install:prepend() {
	cd ${WORKDIR}/${LOKI_UPDATE_REPO_CLONED_BASE}
}

LICENSE = "CLOSED"

S = "${WORKDIR}/git"
