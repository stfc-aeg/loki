SUMMARY = "A recipe for the Loki Update adapter"

HOMEPAGE = "https://github.com/stfc-aeg/loki-update"

RDEPENDS:${PN} += "odin-control (>= 1.6.0)"
RDEPENDS:${PN} += "python3-pyfdt"

# Repo will be cloned into here
LOKI_UPDATE_REPO_CLONED_BASE = "git"

# Pull specific commit from repository
SRCREV = "e618b6cc110302181dbb606822cb349569bf762a"
PV = "0.0+git${SRCPV}"

SRC_URI = "git://github.com/stfc-aeg/loki-update.git;protocol=http;branch=main"

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