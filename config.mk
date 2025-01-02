# BEFORE including this file, define LOKI_DIR as its own location (must be
# relative to the including Makefile.
# Also define AUTOCONF_PARAMS to specify parameters that will be used to
# configure the LOKI project.
#
# To see available parameters, run 'make loki-configure-help' from this
# makefile (or after including this file in the project makefile).
#
# This file will generate the main LOKI project Makefile from Makefile.in

CONF_OUTPUTS= Makefile
CONF_INPUTS= Makefile.in configure

CONF_HW_OUTPUTS= design/Makefile design/design_basic_settings.sh
CONF_HW_INTPUTS= design/Makefile.in design/design_basic_settings.sh.in

# Currently SW is part of the design, and relies on the same files. These variables
# are preserved in case software-specific autoconf-generated files are later required.
CONF_SW_OUTPUTS= 
CONF_SW_INPUTS= 

CONF_OS_OUTPUTS= os/petalinux-custom/Makefile os/petalinux-custom/project-spec/configs/config
CONF_OS_INPUTS= os/petalinux-custom/Makefile.in os/petalinux-custom/project-spec/configs/config.in

# Make these paths relative to the calling makefile's location
CONF_OUTPUTS_PF=$(addprefix ${LOKI_DIR}, ${CONF_OUTPUTS})
CONF_INPUTS_PF=$(addprefix ${LOKI_DIR}, ${CONF_INPUTS})
CONF_HW_OUTPUTS_PF=$(addprefix ${LOKI_DIR}, ${CONF_HW_OUTPUTS})
CONF_HW_INPUTS_PF=$(addprefix ${LOKI_DIR}, ${CONF_HW_INTPUTS})
CONF_SW_OUTPUTS_PF=$(addprefix ${LOKI_DIR}, ${CONF_SW_OUTPUTS})
CONF_SW_INPUTS_PF=$(addprefix ${LOKI_DIR}, ${CONF_SW_INPUTS})
CONF_OS_OUTPUTS_PF=$(addprefix ${LOKI_DIR}, ${CONF_OS_OUTPUTS})
CONF_OS_INPUTS_PF=$(addprefix ${LOKI_DIR}, ${CONF_OS_INPUTS})

$(info autoconf configuring LOKI project at $$LOKI_DIR: ${LOKI_DIR})
$(info $$AUTOCONF_PARAMS are ${AUTOCONF_PARAMS})
$(info $$CONF_HW_OUTPUTS are ${CONF_HW_OUTPUTS_PF})

.PHONY: loki-configure-hw loki-configure-sw loki-configure-os loki-configure-help

# Build ./configure with autoconf
AUTOCONF_OUTPUT=$(addprefix ${LOKI_DIR}, configure)
AUTOCONF_INPUT_AC=$(addprefix ${LOKI_DIR}, configure.ac)
${AUTOCONF_OUTPUT}: ${AUTOCONF_INPUT_AC}
	echo "Creating configure from configure.ac"
	cd ${LOKI_DIR}; autoconf

# Rules relate to HW/SW/OS specifically. This way, if only one has changed,
# the autoconf will rebuild that target file and will not rebuild the unrelated
# outputs of the ./configure, preventing unnecessary rebuilding of other parts
# of the project that haven't actually been reconfigured.
$(CONF_HW_OUTPUTS_PF) ${CONF_SW_OUTPUTS_PF} ${CONF_OS_OUTPUTS_PF} $(CONF_OUTPUTS_PF): $(CONF_HW_INPUTS_PF) ${CONF_SW_INPUTS_PF} ${CONF_OS_INPUTS_PF} $(CONF_INPUTS_PF)
	echo "Configuring LOKI with parameters: ${AUTOCONF_PARAMS}"
	# Generate the configure
	cd ${LOKI_DIR}; autoconf configure.ac

	cd ${LOKI_DIR}; ./configure --prefix=$(shell pwd)/${LOKI_DIR} \
		${AUTOCONF_PARAMS}

# Call from other (application ) makefiles without knowing the files autoconf depends on
loki-configure-hw: ${CONF_HW_OUTPUTS_PF} ${CONF_OUTPUTS_PF}
	# Also force-create the symlinks that external Makefiles may rely on.
	$(MAKE) -C ${LOKI_DIR}/design/ .platform_configured

loki-configure-sw: ${CONF_SW_OUTPUTS_PF} ${CONF_OUTPUTS_PF}

loki-configure-os: ${CONF_OS_OUTPUTS_PF} ${CONF_OUTPUTS_PF}

loki-configure-help:
	cd ${LOKI_DIR}; ./configure --help=short
