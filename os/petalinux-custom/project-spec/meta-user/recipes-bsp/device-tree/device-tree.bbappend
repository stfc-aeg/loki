FILESEXTRAPATHS_prepend := "${THISDIR}/files:"
#FILESEXTRAPATHS_prepend := "${THISDIR}/files/loki_rev1:"
#FILESEXTRAPATHS_prepend := "${THISDIR}/files/tebf0808:"

#COMPATIBLE_MACHINE_loki_rev1 = ".*"

# Base device tree, shared
SRC_URI += "file://system-user.dtsi"

# Supply different device trees to different machines
#SRC_URI_loki_rev1 += "file://loki_rev1/system-user.dtsi"
#SRC_URI_tebf0808 += "file://tebf0808/syste-user.dtsi"
#SRC_URI_append_loki_rev1 += " file://loki_rev1/loki_rev1.dtsi"

python () {
    if d.getVar("CONFIG_DISABLE"):
        d.setVarFlag("do_configure", "noexec", "1")
}

export PETALINUX
do_configure_append () {
	script="${PETALINUX}/etc/hsm/scripts/petalinux_hsm_bridge.tcl"
	data=${PETALINUX}/etc/hsm/data/
	eval xsct -sdx -nodisp ${script} -c ${WORKDIR}/config \
	-hdf ${DT_FILES_PATH}/hardware_description.${HDF_EXT} -repo ${S} \
	-data ${data} -sw ${DT_FILES_PATH} -o ${DT_FILES_PATH} -a "soc_mapping"

    bbdebug 2 "The value of SRC_URI"
    bbdebug 2 ${SRC_URI}
}
