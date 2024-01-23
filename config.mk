# BEFORE including this file, define LOKI_DIR as its own location (must be
# relative to the including Makefile.
# Also define AUTOCONF_PARAMS to specify parameters that will be used to
# configure the LOKI project.
#
# To see available parameters, run 'make loki-configure-help' from this
# makefile (or after including this file in the project makefile).
#
# This file will generate the main LOKI project Makefile from Makefile.in

AUTOCONF_OUTPUTS= Makefile
AUTOCONF_INPUTS= Makefile.in configure

AUTOCONF_HW_OUTPUTS= design/Makefile design/design_basic_settings.sh
AUTOCONF_HW_INTPUTS= design/Makefile.in design/design_basic_settings.sh.in

# Currently SW is part of the design, and relies on the same files. These variables
# are preserved in case software-specific autoconf-generated files are later required.
AUTOCONF_SW_OUTPUTS= 
AUTOCONF_SW_INPUTS= 

AUTOCONF_OS_OUTPUTS= os/petalinux-custom/Makefile os/petalinux-custom/project-spec/configs/config
AUTOCONF_OS_INPUTS= os/petalinux-custom/Makefile.in os/petalinux-custom/project-spec/configs/config.in

# Make these paths relative to the calling makefile's location
AUTOCONF_OUTPUTS_PF=$(addprefix ${LOKI_DIR}, ${AUTOCONF_OUTPUTS})
AUTOCONF_INPUTS_PF=$(addprefix ${LOKI_DIR}, ${AUTOCONF_INPUTS})
AUTOCONF_HW_OUTPUTS_PF=$(addprefix ${LOKI_DIR}, ${AUTOCONF_HW_OUTPUTS})
AUTOCONF_HW_INPUTS_PF=$(addprefix ${LOKI_DIR}, ${AUTOCONF_HW_INTPUTS})
AUTOCONF_SW_OUTPUTS_PF=$(addprefix ${LOKI_DIR}, ${AUTOCONF_SW_OUTPUTS})
AUTOCONF_SW_INPUTS_PF=$(addprefix ${LOKI_DIR}, ${AUTOCONF_SW_INPUTS})
AUTOCONF_OS_OUTPUTS_PF=$(addprefix ${LOKI_DIR}, ${AUTOCONF_OS_OUTPUTS})
AUTOCONF_OS_INPUTS_PF=$(addprefix ${LOKI_DIR}, ${AUTOCONF_OS_INPUTS})

$(info autoconf configuring LOKI project at $$LOKI_DIR: ${LOKI_DIR})
$(info $$AUTOCONF_PARAMS are ${AUTOCONF_PARAMS})
$(info $$AUTOCONF_HW_OUTPUTS are ${AUTOCONF_HW_OUTPUTS_PF})

.PHONY: loki-configure-hw loki-configure-sw loki-configure-os loki-configure-help

# Rules relate to HW/SW/OS specifically. This way, if only one has changed,
# the autoconf will rebuild that target file and will not rebuild the unrelated
# outputs of the ./configure, preventing unnecessary rebuilding of other parts
# of the project that haven't actually been reconfigured.
$(AUTOCONF_HW_OUTPUTS_PF) ${AUTOCONF_SW_OUTPUTS_PF} ${AUTOCONF_OS_OUTPUTS_PF} $(AUTOCONF_OUTPUTS_PF): $(AUTOCONF_HW_INPUTS_PF) ${AUTOCONF_SW_INPUTS_PF} ${AUTOCONF_OS_INPUTS_PF} $(AUTOCONF_INPUTS_PF)
	echo "Configuring LOKI with parameters: ${AUTOCONF_PARAMS}"
	cd ${LOKI_DIR}; ./configure --prefix=$(shell pwd)/${LOKI_DIR} \
		${AUTOCONF_PARAMS}

# Call from other (application ) makefiles without knowing the files autoconf depends on
loki-configure-hw: ${AUTOCONF_HW_OUTPUTS_PF} ${AUTOCONF_OUTPUTS_PF}

loki-configure-sw: ${AUTOCONF_SW_OUTPUTS_PF} ${AUTOCONF_OUTPUTS_PF}

loki-configure-os: ${AUTOCONF_OS_OUTPUTS_PF} ${AUTOCONF_OUTPUTS_PF}

loki-configure-help:
	cd ${LOKI_DIR}; ./configure --help=short
