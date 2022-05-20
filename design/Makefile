SHELL := /bin/bash

.PHONY: hardware software all os clean

PLATFORM = 4cg_2gb
OS_PATH = ./os/petalinux-custom/

all: os

HARDWARE_OUTPUT = prebuilt/hardware/${PLATFORM}/design_${PLATFORM}.xsa
SOFTWARE_OUTPUT = prebuilt/software/${PLATFORM}/fsbl.elf prebuilt/software/${PLATFORM}/pmufw.elf

HARDWARE_DEPS = $(shell find ./block_design/)
HARDWARE_DEPS := $(shell find ./constraints/)
${HARDWARE_OUTPUT}: ${HARDWARE_DEPS}
	$(info Modified hardware synth dependencies: $?)
	#LOKI_AUTO_BUILD="HW"; \
	#source ./vivado_open_existing_project_guimode.sh
	touch ${HARDWARE_OUTPUT}
	$(info finished building hardware)
hardware: ${HARDWARE_OUTPUT} ;

SOFTWARRE_DEPS = $(shell find ../../sw_lib/sw_apps/)
${SOFTWARE_OUTPUT}: ${HARDWARE_OUTPUT} ${SOFTWARE_DEPS}
	$(info Modified software dependencies: $?)
	#LOKI_AUTO_BUILD="SW"; \
	#source ./vivado_open_existing_project_guimode.sh
	touch ${SOFTWARE_OUTPUT}
	$(info finished building FSBL and PMUFW)
software: ${SOFTWARE_OUTPUT} ;

os: hardware software
	$(MAKE) -C ${OS_PATH} all

clean:
	rm -rf prebuilt/hardware/*
	rm -rf prebuitt/software/*
	$(MAKE) -C ${OS_PATH} clean

clobber:
	#TODO delete the project so that it must be re-configured fresh
