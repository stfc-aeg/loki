
SRC_URI_append ="\
    file://config\
"
extra_settings = ""
FILESEXTRAPATHS_append := ":${sysconf}"
ATF_CONSOLE_zynqmp = "cadence"
EXTRA_OEMAKE_append = " ${extra_settings} PRELOADED_BL33_BASE=${atf_bl33_load}"
atf_bl33_load = "0x8000000"
sysconf = "${TOPDIR}/../project-spec/configs"
