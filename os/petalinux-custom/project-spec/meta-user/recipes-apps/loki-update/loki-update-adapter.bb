SUMMARY = "A recipe for the Loki Update adapter"

HOMEPAGE = "https://github.com/stfc-aeg/loki-update"

RDEPENDS_${PN} += "odin-control (= 1.6.0)"
RDEPENDS_${PN} += "python3-pyfdt"

# Repo will be cloned into here
LOKI_UPDATE_REPO_CLONED_BASE = "git"

# Pull specific commit from repository
SRCREV = "e618b6cc110302181dbb606822cb349569bf762a"
PV = "0.0+git${SRCPV}"

SRC_URI = "git://git@github.com/stfc-aeg/loki-update.git;protocol=ssh;branch=main"

inherit setuptools3

do_configure_prepend() {
	cd ${WORKDIR}/${LOKI_UPDATE_REPO_CLONED_BASE}
}

do_compile_prepend() {
	cd ${WORKDIR}/${LOKI_UPDATE_REPO_CLONED_BASE}
}

do_install_prepend() {
	cd ${WORKDIR}/${LOKI_UPDATE_REPO_CLONED_BASE}
}

LICENSE = "CLOSED"