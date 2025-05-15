inherit odin-control-instance

SUMMARY = "A recipe for the Loki Update application"

HOMEPAGE = "https://github.com/stfc-aeg/loki-update"

RDEPENDS_${PN} += "loki-update-adapter"

S = "${WORKDIR}"

REACT_UI_TAG = "v0.0.8"

# React UI will end up here
REACT_SOURCE_PATH = "loki-update-ui-${REACT_UI_TAG}"

# Repo will be cloned into here
LOKI_UPDATE_REPO_CLONED_BASE = "git"

# Pull specific commit from repository
SRCREV = "ca742b84bfeb14a1f440c7192a356799cf716e3d"
PV = "0.0+git${SRCPV}"

SRC_URI = "git://git@github.com/stfc-aeg/loki-update.git;protocol=ssh;branch=main \
           https://github.com/stfc-aeg/loki-update/releases/download/${REACT_UI_TAG}/build.zip;subdir=${REACT_SOURCE_PATH};name=react-build-zip \
           file://loki-update-config.conf \
           "

# Checksum specifically for the react UI
SRC_URI[react-build-zip.sha256sum] = "3df8210d5c3703295cf850bddad427bbfbed1e90d583299a38410b1d4ee30329"

LICENSE = "CLOSED"

REPO_CONFIG_PATH = "${LOKI_UPDATE_REPO_CLONED_BASE}/test/config/loki-update.cfg"
REPO_STATIC_PATH_${PN} = "${REACT_SOURCE_PATH}"

do_install_append() {
    install -d ${D}${base_prefix}/etc/conf.d/loki-config
    install -m 0644 '${WORKDIR}/loki-update-config.conf' '${D}${base_prefix}/etc/conf.d/loki-config/loki-update-config.conf'
}

FILES_${PN} += "${base_prefix}/opt/loki-detector/instances/${PN}/*"
FILES_${PN} += "${base_prefix}/etc/conf.d/loki-config/*"