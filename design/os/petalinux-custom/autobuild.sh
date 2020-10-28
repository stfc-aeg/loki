#!/bin/bash

usage() {
	printf '\nThis script will build and package the PetaLinux project into BOOT.BIN, image.ub and boot.scr\n'
	printf 'With no arguments, petalinux-build and petalinux-package will be run. The build will include\n fsbl.elf, u-boot.elf, bl31.elf, system.bit (fpga), and pmufw.elf.'
	printf '\n If any stage that is being run fails, the script will exit.\n'
	printf '\nUsage :\t$ ./autobuild.sh [arguments]\n'
	printf '\n\tArguments:\n'
	printf '\t\t-h\t--help\t\tDisplay this help message\n'
	printf '\t\t-x\t--xsa\t\tWill import the latest hardware description .XSA from Trenz.\n'
	printf '\t\t-s\t--sw\t\tWill import the latest fsbl and pmufw from Trenz.\n'
	printf '\t\t-b\t--nobuild\tSkip execution of petalinux-build.\n'
	printf '\t\t-p\t--nopkg\t\tPerform petalinux-package with for boot, with u-boot,\n\t\t\t\t\tfsbl, pmufw, atf and fpga arguments specified.\n\t\t\t\t\tScript will terminate if package fails.\n'
	printf '\t\t-q\t--qemu\t\tBoot built image in QEMU with u-boot and kernel.\n'
}

# Get arguments from terminal
nobuild=0	# Default: build active
nopkg=0		# Default: package active
noqemu=1	# Default: qemu inactive
noxsa=1		# Default: XSA import inactive
nosw=1		# Default: software import inactive

TEMP=`getopt -o bpqxsh --long nobuild,nopkg,qemu,xsa,sw,help -- "$@"`
eval set -- "$TEMP"
while true; do
	case "$1" in
		-b | --nobuild) nobuild=1; shift ;;
		-p | --nopkg) nopkg=1; shift ;;
		-q | --qemu) noqemu=0; shift ;;
		-x | --xsa) noxsa=0; shift ;;
		-s | --sw) nosw=0; shift ;;
		-h | --help) usage; exit 0 ;;
		--) shift; break ;;
		*) break ;;
	esac
done



# Output directory
OUTPUT_DIR="./images/linux/"

# Printout formatting
PRE="\t#> "
PREIND="\t#\t> "
SUF="\n\n"

# Create output directory if it does not yet exist
mkdir -p ${OUTPUT_DIR}

# Import XSA hardware description
if [ $noxsa = 0 ] ; then
	printf "\n $(date +%T) $PRE XSA Import Enabled, starting...$SUF"

	# Remove any .xsa files in the Petalinux project root
	rm -rf ./*.xsa
	printf "\n $(date +%T) $PREIND Old .xsa files removed from cwd...$SUF"

	# Copy the latest .xsa into the PetaLinux project root
	if cp ../../prebuilt/hardware/4cg_2gb/design_4cg_2gb.xsa ./ ; then

		# Silently run config to import XSA without menuconfig
		if petalinux-config --get-hw-description --silentconfig ; then
			printf "\n $(date +%T) $PREIND New XSA imported...$SUF"
		else
			printf "\n $(date +%T) $PREIND XSA config-import failed.$SUF"
			exit 3
		fi
	else
		printf "\n $(date +%T) $PREIND Trenz project XSA not found.$SUF"
		exit 4
	fi
else
	printf "\n $(date +%T) $PRE XSA Import Disabled (enable with --xsa)$SUF"
fi

# Import FSBL and PMUFW
if [ $nosw  = 0 ] ; then
	printf "\n $(date +%T) $PRE FSBL and PMUFW Import Enabled, starting...$SUF"

	# Replace current fsbl with Trenz-generated one
	if cp ../../prebuilt/software/4cg_2gb/fsbl.elf ${OUTPUT_DIR} ; then
		printf "\n $(date +%T) $PREIND New FSBL imported...$SUF"
	else
		printf "\n $(date +%T) $PREIND Trenz project FSBL not found.$SUF"
		exit 5
	fi

	# Replace current pmufw with Trenz-generated one
	if cp ../../prebuilt/software/4cg_2gb/pmufw.elf ${OUTPUT_DIR} ; then
		printf "\n $(date +%T) $PREIND New PMUFW imported...$SUF"
	else
		printf "\n $(date +%T) $PREIND Trenz project PMUFW not found.$SUF"
		exit 6
	fi
else
	printf "\n $(date +%T) $PRE FSBL and PMUFW Import Disabled (enable with --sw)$SUF"
fi

# PetaLinux Build
if [ $nobuild = 0 ] ; then
	printf "\n $(date +%T) $PRE PetaLinux Build Enabled, starting...$SUF"
	if petalinux-build ; then
		printf "\n $(date +%T) $PREIND PetaLinux Build Passed$SUF"
	else
		printf "\n $(date +%T) $PREIND PetaLinux Build Failed$SUF"
		exit 1
	fi
else
	printf "\n $(date +%T) $PRE PetaLinux Build Disabled$SUF"
fi

# PetaLinux Package
if [ $nopkg = 0 ] ; then
	printf "\n $(date +%T) $PRE PetaLinux Package Enabled, starting...$SUF"
	if petalinux-package --boot --u-boot \
		--fsbl ${OUTPUT_DIR}fsbl.elf \
		--pmufw ${OUTPUT_DIR}pmufw.elf \
		--atf ${OUTPUT_DIR}bl31.elf \
		--fpga ${OUTPUT_DIR}system.bit \
		--force ; then
		printf "\n $(date +%T) $PREIND PetaLinux Package Passed$SUF"
		dtc -I dtb -O dts -o ${OUTPUT_DIR}system.dts ${OUTPUT_DIR}system.dtb
		printf "\n $(date +%T) $PREIND New device tree exported to ${OUTPUT_DIR}system.dts$SUF"
	else
		printf "\n $(date +%T) $PREIND PetaLinux Package Failed$SUF"
		exit 2
	fi
else
	printf "\n $(date +%T) $PRE PetaLinux Package Disabled$SUF"
fi

# PetaLinux Boot (with QEmu)
if [ $noqemu = 0 ] ; then
	printf "\n $(date +%T) $PRE PetaLinux QEmu Enabled, starting...$SUF"
	petalinux-boot --qemu --kernel
else
	printf "\n $(date +%T) $PRE PetaLinux QEmu Disabled (enable with --qemu)$SUF"
fi

