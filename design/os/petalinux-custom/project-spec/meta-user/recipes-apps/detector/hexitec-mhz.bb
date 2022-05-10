SUMMARY = "This is a recipe for the HEXITEC-MHz Odin-Control Instance"

# RDEPENDS specifies packages that are required at runtime on the host, as well as for build.
RDEPENDS_${PN} += "python3-setuptools"
RDEPENDS_${PN} += "odin-control (= 1.2.0)"
RDEPENDS_${PN} += "odin-sequencer"
RDEPENDS_${PN} += "odin-devices (=1.1.0)"
RDEPENDS_${PN} += "python3-msgpack"
RDEPENDS_${PN} += "loki-config"
RDEPENDS_${PN} += "loki-user"
DEPENDS += "loki-user"

# Repo URL. NOTE: Remove branch speficiation when back on master
SRC_URI = "git://github.com/stfc-aeg/mercury-detector.git;branch=add-carrier-adapter \
           file://0001-Change-default-interface-from-127.0.0.1-to-0.0.0.0.patch \
           "

# Pull specific commit from mercury-detector repository
SRCREV = "33d158413ea9e818443d7db649760848122ec0c9"
PV = "0.0+git${SRCPV}"

# This has to be in the format expected in Yocto's license list...
LICENSE = "CLOSED"

S = "${WORKDIR}/git/"

# Used to determine non-standard location of setup.py for setuptools
DISTUTILS_SETUP_PATH = "${S}/control"

STATIC_RESOURCES_INSTALL_PATH = "/opt/loki-detector/"
STATIC_RESOURCES_REPO_PATH = "/test"
STATIC_RESOURCES_CONF_LOC = "/test/config/test_emulator.cfg"
SEQUENCES_LOC = "/test/sequences"

LOKI_CONFIG_DESTINATION = "/opt/loki-detector/config.cfg"
LOKI_SEQUENCES_DESTINATION = "/opt/loki-detector/sequences"

LOKI_USERNAME = "loki"

inherit setuptools3
inherit useradd

USERADD_PACKAGES = "${PN}"

USERADD_PARAM_${PN} = "-d /home/${LOKI_USERNAME} -r -s /bin/bash ${LOKI_USERNAME}"

do_configure_prepend() {
	cd ${DISTUTILS_SETUP_PATH}
	bbdebug 2 "Current working directory (pwd):" ${pwd}
	bbdebug 2 "Build Directory:" ${B}
	bbdebug 2 "WORKDIR Directory:" ${WORKDIR}
	bbdebug 2 "Source Directory:" ${S}
	bbdebug 2 "setup.py location:" ${DISTUTILS_SETUP_PATH}
}

do_compile_prepend() {
	cd ${DISTUTILS_SETUP_PATH}
	bbdebug 2 "Current working directory (pwd):" ${pwd}
	bbdebug 2 "Build Directory:" ${B}
	bbdebug 2 "WORKDIR Directory:" ${WORKDIR}
	bbdebug 2 "Source Directory:" ${S}
	bbdebug 2 "setup.py location:" ${DISTUTILS_SETUP_PATH}
}

do_install_prepend() {
	# Change directory to setup.py location when not in repository root
	cd ${DISTUTILS_SETUP_PATH}
}

do_install_append() {
	# With the python module installed, the static resources need to be installed into rootfs

	# Create the config directory
    install -d ${D}${base_prefix}${STATIC_RESOURCES_INSTALL_PATH}

	# Install individual file in destination
	#install -m 0644 '${DISTUTILS_SETUP_PATH}/test/config/test_emulator.cfg' '${D}${base_prefix}/opt/hexitec-mhz-detector/config/test_emulator.cfg'

	# gnu install does not work well for recursive directories, so copy recursively
	cp -R '${DISTUTILS_SETUP_PATH}${STATIC_RESOURCES_REPO_PATH}' '${D}${base_prefix}${STATIC_RESOURCES_INSTALL_PATH}'
    chown -R ${LOKI_USERNAME} '${D}${base_prefix}${STATIC_RESOURCES_INSTALL_PATH}'

    # To comply with generic loki detector, the configuration file should be placed or symlinked to the loki opt directory
    cd /
    ln -sfr '${D}${base_prefix}${STATIC_RESOURCES_INSTALL_PATH}${STATIC_RESOURCES_CONF_LOC}' '${D}${base_prefix}${LOKI_CONFIG_DESTINATION}'
    chown -R ${LOKI_USERNAME} '${D}${base_prefix}${LOKI_CONFIG_DESTINATION}'

    # To comply with generic loki detector, the sequences directory should be placed or symlinked to the loki opt directory
    cd /
    ln -sfr '${D}${base_prefix}${STATIC_RESOURCES_INSTALL_PATH}${SEQUENCES_LOC}' '${D}${base_prefix}${LOKI_SEQUENCES_DESTINATION}'
    chown -R ${LOKI_USERNAME} '${D}${base_prefix}${LOKI_SEQUENCES_DESTINATION}'
}

# include the rootfs build directory locations in the yocto rootfs on exit
FILES_${PN} += "${base_prefix}/opt/*"
FILES_${PN} += "${base_prefix}/etc/init.d/*"
FILES_${PN} += "${base_prefix}${sysconfdir}/*"
