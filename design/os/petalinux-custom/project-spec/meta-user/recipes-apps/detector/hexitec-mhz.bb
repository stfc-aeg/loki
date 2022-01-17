SUMMARY = "This is a recipe for the HEXITEC-MHz Odin-Control Instance"

# RDEPENDS specifies packages that are required at runtime on the host, as well as for build.
RDEPENDS_${PN} += "python3-setuptools"
#RDEPENDS_${PN} += "odin-control (=1.0.0)"
RDEPENDS_${PN} += "odin-control (>=1.0.0)"
RDEPENDS_${PN} += "odin-sequencer"
RDEPENDS_${PN} += "odin-devices (=1.0.0)"

# Repo URL. NOTE: Remove branch speficiation when back on master
SRC_URI = "git://github.com/stfc-aeg/mercury-detector.git;branch=add-carrier-adapter \
		file://hexitec-mhz-startup.sh"

SRCREV = "0e6f7f55de34de80cdb7e1fa6447a15cd9ba16b3"
PV = "0.0+git${SRCPV}"

# This has to be in the format expected in Yocto's license list...
LICENSE = "CLOSED"

S = "${WORKDIR}/git/"
DISTUTILS_SETUP_PATH = "${S}/control"

STARTUP_SCRIPT_NAME = "hexitec-mhz-startup.sh"
STATIC_RESOURCES_REPO_PATH = "/test"
STARTUP_SCRIPT_RUNLEVEL = "S"

inherit setuptools3

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
	install -d  ${D}${base_prefix}/opt/hexitec-mhz-detector

	# Install individual file in destination
	#install -m 0644 '${DISTUTILS_SETUP_PATH}/test/config/test_emulator.cfg' '${D}${base_prefix}/opt/hexitec-mhz-detector/config/test_emulator.cfg'

	# gnu install does not work well for recursive directories, so copy recursively
	cp -R '${DISTUTILS_SETUP_PATH}${STATIC_RESOURCES_REPO_PATH}' '${D}${base_prefix}/opt/hexitec-mhz-detector/'

	# Other attempts
	#find '${DISTUTILS_SETUP_PATH}/test/config' -type f -exec 'install -m 0644 "{}" -D --target-directory=${D}${base_prefix}/opt/hexitec-mhz-detector/config/' \;
	#install -m 0644 '${DISTUTILS_SETUP_PATH}/test/config' '${D}${base_prefix}/opt/hexitec-mhz-detector/config/'

	# Install odin_server startup script into init.d
	install -d ${D}${base_prefix}/etc/init.d
	install -m 0644 '${WORKDIR}/hexitec-mhz-startup.sh' '${D}${base_prefix}/etc/init.d/hexitec-mhz-startup.sh'

	# Set the script to run at startup by symlinking in to startup runlevel
	install -d ${D}${sysconfdir}/rcS.d
	ln -sf ../init.d/hexitec-mhz-startup.sh  ${D}${sysconfdir}/rcS.d/S90hexitec-mhz-startup.sh
}

# include the rootfs build directory locations in the yocto rootfs on exit
FILES_${PN} += "${base_prefix}/opt/*"
FILES_${PN} += "${base_prefix}/etc/init.d/*"
FILES_${PN} += "${base_prefix}${sysconfdir}/*"
