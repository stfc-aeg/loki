PLATFORM = 4cg_2gb
HW_EXPORT_DIR = ../../prebuilt/hardware/${PLATFORM}
HW_XSA_FILENAME = design_${PLATFORM}.xsa
SW_EXPORT_DIR = ../../prebuilt/software/${PLATFORM}
SW_FSBL_FILENAME = fsbl.elf
SW_PMUFW_FILENAME = pmufw.elf
PL_ROOT = .
OUTPUT_DIR = ${PL_ROOT}/images/linux

DESIGN_BITSTREAM = ${PL_ROOT}/${HW_XSA_FILENAME}
PL_PROJ_BITSTREAM = ${PL_ROOT}/project-spec/hw-description/system.xsa
LOW_LEVEL_SW = ${SW_EXPORT_DIR}${SW_FSBL_FILENAME} ${SW_EXPORT_DIR}${SW_PMUFW_FILENAME}
LOW_LEVEL_SW_LOCAL = ${OUTPUT_DIR}${SW_FSBL_FILENAME} ${OUTPUT_DIR}${SW_PMUFW_FILENAME}
DTS = ${OUTPUT_DIR}/system.dts
DTB = ${OUTPUT_DIR}/system.dtb

# The yocto workspace contains recipes brought into the workspace under modification.
BUILD_DEPS = $(shell find ${PL_ROOT}/components/yocto/workspace/ -type f)
#project-spec contains main user recipes and config.
BUILD_DEPS := $(shell find ${PL_ROOT}/project-spec/ -type f)

.PHONY: default all build package rootfs simulate clean mostlyclean

# Build all required files for upload to hardware, plus human-readable device tree
all: ${OUTPUT_DIR}/BOOT.BIN ${OUTPUT_DIR}/boot.scr ${OUTPUT_DIR}/image.ub ${DTS} ;

# If the bitstream has been imported into the project it will appear here
${PL_PROJ_BITSTREAM}: ${HW_EXPORT_DIR}/${HW_XSA_FILENAME}
	# Copy the latest design into this directory
	cp ${HW_EXPORT_DIR}/${HW_XSA_FILENAME} ${DESIGN_BITSTREAM}

	# Use PetaLinux tools to install new design
	mkdir -p project-spec/hw-description
	petalinux-config --get-hw-description --silentconfig

# Create the output directory if required
${OUTPUT_DIR}:
	$(info Creating non-existent output directory...)
	mkdir -p ${OUTPUT_DIR}

# Local directory file depends on Xilinx build path
${OUTPUT_DIR}/${SW_FSBL_FILENAME}: ${SW_EXPORT_DIR}/${SW_FSBL_FILENAME} | ${OUTPUT_DIR}
	# Replace current fsbl with Trenz-generated one
	$(info Exporting Generated FSBL to output directory)
	cp ${SW_EXPORT_DIR}/${SW_FSBL_FILENAME} ${OUTPUT_DIR}/${SW_FSBL_FILENAME}

# Local directory file depends on Xilinx build path
${OUTPUT_DIR}/${SW_PMUFW_FILENAME}: ${SW_EXPORT_DIR}/${SW_PMUFW_FILENAME} | ${OUTPUT_DIR}
	# Replace current pmufw with Trenz-generated one
	$(info Exporting Generated PMUFW to output directory)
	cp ${SW_EXPORT_DIR}/${SW_PMUFW_FILENAME} ${OUTPUT_DIR}/${SW_PMUFW_FILENAME}

# Create intermediate product so that PHONY is not executed unless changes have been made
# This means that build can provide multiple files without multiple runs
${OUTPUT_DIR}/.build_complete: ${PL_PROJ_BITSTREAM} ${BUILD_DEPS}
	$(info Modified build dependencies: $?)
	$(info performing petalinux-build...)
	petalinux-build
	touch ${OUTPUT_DIR}/.build_complete
build: ${OUTPUT_DIR}/.build_complete ;

${OUTPUT_DIR}/system.bit: build ;
${OUTPUT_DIR}/bl31.elf: build ;
${OUTPUT_DIR}/system.dtb: build ;

# rootfs is several output files. However, this is the one that is required to be included
# in the image.ub.
${OUTPUT_DIR}/rootfs.cpio.gz: build ;

# Create intermediate product so that PHONY is not executed unless changes have been made
# This means that package can provide multiple files without multiple runs
${OUTPUT_DIR}/.package_complete: ${OUTPUT_DIR}/rootfs.cpio.gz ${OUTPUT_DIR}/fsbl.elf ${OUTPUT_DIR}/pmufw.elf ${OUTPUT_DIR}/bl31.elf ${OUTPUT_DIR}/system.bit ${OUTPUT_DIR}/system.dtb
	$(info PetaLinux Package Enabled, starting...)
	petalinux-package --boot --u-boot \
		--fsbl ${OUTPUT_DIR}/fsbl.elf \
		--pmufw ${OUTPUT_DIR}/pmufw.elf \
		--atf ${OUTPUT_DIR}/bl31.elf \
		--fpga ${OUTPUT_DIR}/system.bit \
		--force
	$(info PetaLinux Package Passed)
	touch ${OUTPUT_DIR}/.package_complete
package: ${OUTPUT_DIR}/.package_complete ;

${OUTPUT_DIR}/BOOT.BIN: package ;
${OUTPUT_DIR}/boot.scr: package ;
${OUTPUT_DIR}/image.ub: package ;

${DTS}: ${DTB}
	dtc -I dtb -O dts -o ${OUTPUT_DIR}/system.dts ${OUTPUT_DIR}/system.dtb
	$(info New device tree exported to ${OUTPUT_DIR}/system.dts)

${PL_ROOT}/pre-built/linux/images/pmu_rom_qemu_sha3.elf:
	$(warning pmu_rom_qemu_sha3.elf is not automatically build and must be obtained from Xilinx)
	$(warning See https://github.com/Xilinx/meta-xilinx/blob/master/meta-xilinx-core/README.qemu.md)
	$(warning Place file in pre-built/linux/images/ (create if necessary))
	$(error pmu_rom_qemu_sha3.elf was not found)

simulate: package ${PL_ROOT}/pre-built/linux/images/pmu_rom_qemu_sha3.elf ${OUTPUT_DIR}/zynqmp-qemu-multiarch-arm.dtb ${OUTPUT_DIR}/zynqmp-qemu-multiarch-pmu.dtb ${OUTPUT_DIR}/zynqmp-qemu-arm.dtb ${OUTPUT_DIR}/Image ${OUTPUT_DIR}/rootfs.cpio.gz.u-boot
	$(info PetaLinux QEmu Enabled, starting...)
	petalinux-boot --qemu --kernel

mostlyclean:
	# Remove hidden build sentinel files, forcing re-build and re-package without deleting build
	# This is because PetaLinux will not re-generate files that should not have changed unless
	# a full clean is made.
	rm -rfv ${OUTPUT_DIR}/.*complete

clean:
	# Completely remove the images and build directory. May take considerable time to re-build.
	petalinux-build -x mrproper

	# Force next build to re-import hardware from hardware export directory
	rm -rf ${DESIGN_BITSTREAM}
	rm -rf ${PL_PROJ_BITSTREAM}
