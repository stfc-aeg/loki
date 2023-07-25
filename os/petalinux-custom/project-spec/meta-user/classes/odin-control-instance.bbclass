# RDEPENDS specifies packages that are required at runtime on the host, as well as for build.
RDEPENDS_${PN} += "python3-setuptools"
RDEPENDS_${PN} += "odin-control (= 1.3.0)"
RDEPENDS_${PN} += "odin-sequencer (=0.2.0)"
RDEPENDS_${PN} += "odin-devices (=1.1.0)"
RDEPENDS_${PN} += "python3-msgpack"
RDEPENDS_${PN} += "python3-matplotlib"
RDEPENDS_${PN} += "python3-pillow"
RDEPENDS_${PN} += "loki-config"
RDEPENDS_${PN} += "loki-user"
DEPENDS += "loki-user"


# Special function line that will cause package not to own parent directories of
# the files packaged.
DIRFILES = "1"

LOKI_RESOURCES_INSTALL_PATH = "/opt/loki-detector/"

# Destinations relative to resource install path
LOKI_CONFIG_DESTINATION = "config.cfg"
LOKI_SEQUENCES_DESTINATION = "sequences"
LOKI_STATIC_DESTINATION = "static"

LOKI_USERNAME = "loki"

inherit setuptools3

do_configure_prepend() {
	cd ${S}/${DISTUTILS_SETUP_PATH}
	bbdebug 2 "Current working directory (pwd):" ${pwd}
	bbdebug 2 "Build Directory:" ${B}
	bbdebug 2 "WORKDIR Directory:" ${WORKDIR}
	bbdebug 2 "Source Directory:" ${S}
	bbdebug 2 "setup.py location:" ${S}/${DISTUTILS_SETUP_PATH}
}

do_compile_prepend() {
	cd ${S}/${DISTUTILS_SETUP_PATH}
	bbdebug 2 "Current working directory (pwd):" ${pwd}
	bbdebug 2 "Build Directory:" ${B}
	bbdebug 2 "WORKDIR Directory:" ${WORKDIR}
	bbdebug 2 "Source Directory:" ${S}
	bbdebug 2 "setup.py location:" ${S}/${DISTUTILS_SETUP_PATH}
}

do_install_prepend() {
	# Change directory to setup.py location when not in repository root
	cd ${S}/${DISTUTILS_SETUP_PATH}
}

copy_resource_protected() {
    # Copy a resource (directory/file) from the source repository into the LOKI filesystem.
    # Usage:
    #  copy_resource_protected <repository_source_path> <install directory root>
    #  Note that all installation will be into subdirectories of ${LOKI_INSTALL_PATH}
    #  Will be read-only by loki user by default (see loki_rw)
	bbplain "Copying repo resource $1 to LOKI resource store subdirectory: $2"
    cp -R "${S}/${1}" "${D}${base_prefix}/${LOKI_RESOURCES_INSTALL_PATH}/${2}"
}

loki_chown() {
    # Change ownership so that the loki user can write the resource
    # Usage:
    #   loki_chown <target>
    #   Note that target is the directory in LOKI, and it must already be installed.
    #   The path is relative to the LOKI resource root ${LOKI_INSTALL_PATH}
	bbplain "Changing ownership of $1 to LOKI user (${LOKI_USERNAME})"
    cd /
    chown ${LOKI_USERNAME}:${LOKI_USERNAME} ${D}${base_prefix}${LOKI_RESOURCES_INSTALL_PATH}/$1
}

loki_mkdir() {
    # Create a new directory relative to the root loki resource install path
    # Usage:
    #   loki_mkdir <target>
	bbplain "Creating new directory $1 in LOKI filesystem"
    cd /
    install -d ${D}${base_prefix}${LOKI_RESOURCES_INSTALL_PATH}/$1
}

do_install_append() {
	# With the python module installed, the static resources need to be installed into rootfs

	# Create the base install directory
    install -d ${D}${base_prefix}${LOKI_RESOURCES_INSTALL_PATH}

	# gnu install does not work well for recursive directories, so copy recursively the standardised
    # paths. These should be defined in the application code.
    copy_resource_protected '${REPO_STATIC_PATH}' '${LOKI_STATIC_DESTINATION}'
    copy_resource_protected '${REPO_SEQUENCES_PATH}' '${LOKI_SEQUENCES_DESTINATION}'
    copy_resource_protected '${REPO_CONFIG_PATH}' '${LOKI_CONFIG_DESTINATION}'

    # Create a loki-writeable directory
    loki_mkdir 'outputs'
    loki_chown 'outputs'

    # Application-specific recipe could extend this function, and make use of the util
    # functions above to install / configure additional directories within LOKI's
    # resource path.
}

# include the rootfs build directory locations in the yocto rootfs on exit
FILES_${PN} += "${base_prefix}${LOKI_RESOURCES_INSTALL_PATH}/*"
FILES_${PN} += "${base_prefix}/etc/init.d/*"
FILES_${PN} += "${base_prefix}${sysconfdir}/*"
