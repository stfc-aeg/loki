FILESEXTRAPATHS_prepend := "${THISDIR}/${PN}:"

SRC_URI += "file://devtool-fragment.cfg \
            file://0001-Restore-cached-I2C-mux-channel.patch \
            "

PV = "5.15"

# Override the bbclass upgrade for kernel versions since 5.8. This is backwards compatible. The only relevant change is
# the Module.symvers line now checks for teh presence of the file before copying it. Unfortunately there is no way to include
# a custom versino of the kernel.bbclass in the user layer and override the built-in one (layer priority does not apply to
# class files, only the layer inclusion order in the bblayers.conf, which for PetaLinux is auto-generated. The order of the
# layers in this file cannot be influenced by any project files that are not generated after build.
do_shared_workdir () {
	cd ${B}

	kerneldir=${STAGING_KERNEL_BUILDDIR}
	install -d $kerneldir

	#
	# Store the kernel version in sysroots for module-base.bbclass
	#

	echo "${KERNEL_VERSION}" > $kerneldir/${KERNEL_PACKAGE_NAME}-abiversion

	# Copy files required for module builds
	cp System.map $kerneldir/System.map-${KERNEL_VERSION}
	[ -e Module.symvers ] && cp Module.symvers $kerneldir/
	cp .config $kerneldir/
	mkdir -p $kerneldir/include/config
	cp include/config/kernel.release $kerneldir/include/config/kernel.release
	if [ -e certs/signing_key.x509 ]; then
		# The signing_key.* files are stored in the certs/ dir in
		# newer Linux kernels
		mkdir -p $kerneldir/certs
		cp certs/signing_key.* $kerneldir/certs/
	elif [ -e signing_key.priv ]; then
		cp signing_key.* $kerneldir/
	fi

	# We can also copy over all the generated files and avoid special cases
	# like version.h, but we've opted to keep this small until file creep starts
	# to happen
	if [ -e include/linux/version.h ]; then
		mkdir -p $kerneldir/include/linux
		cp include/linux/version.h $kerneldir/include/linux/version.h
	fi

	# As of Linux kernel version 3.0.1, the clean target removes
	# arch/powerpc/lib/crtsavres.o which is present in
	# KBUILD_LDFLAGS_MODULE, making it required to build external modules.
	if [ ${ARCH} = "powerpc" ]; then
		if [ -e arch/powerpc/lib/crtsavres.o ]; then
			mkdir -p $kerneldir/arch/powerpc/lib/
			cp arch/powerpc/lib/crtsavres.o $kerneldir/arch/powerpc/lib/crtsavres.o
		fi
	fi

	if [ -d include/generated ]; then
		mkdir -p $kerneldir/include/generated/
		cp -fR include/generated/* $kerneldir/include/generated/
	fi

	if [ -d arch/${ARCH}/include/generated ]; then
		mkdir -p $kerneldir/arch/${ARCH}/include/generated/
		cp -fR arch/${ARCH}/include/generated/* $kerneldir/arch/${ARCH}/include/generated/
	fi

	if (grep -q -i -e '^CONFIG_UNWINDER_ORC=y$' $kerneldir/.config); then
		# With CONFIG_UNWINDER_ORC (the default in 4.14), objtool is required for
		# out-of-tree modules to be able to generate object files.
		if [ -x tools/objtool/objtool ]; then
			mkdir -p ${kerneldir}/tools/objtool
			cp tools/objtool/objtool ${kerneldir}/tools/objtool/
		fi
	fi
}
