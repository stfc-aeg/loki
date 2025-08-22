FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI:append = " file://system-user.dtsi"

require ${@'device-tree-sdt.inc' if d.getVar('SYSTEM_DTFILE') != '' else ''}

do_configure:prepend() {
    # Insert some data from variables into loki-metadata additional dtsi.
	bbplain "Installing metadata into inner runtime devicetree for ${LOKI_METADATA_APPLICATION_NAME}"
    cat <<FILEEND > ${WORKDIR}/loki-info.dtsi
/ {
	loki-metadata {
		application-name = "${LOKI_METADATA_APPLICATION_NAME}";
		application-version = "${LOKI_METADATA_APPLICATION_VERSION}";
		loki-version = "${LOKI_METADATA_LOKI_VERSION}";
		platform = "${LOKI_METADATA_PLATFORM}";
	};
 };	// This space prevents the Yocto parser from breaking, don't remove it
FILEEND
}
