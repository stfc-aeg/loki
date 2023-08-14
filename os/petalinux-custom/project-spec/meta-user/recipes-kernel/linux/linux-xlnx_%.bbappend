FILESEXTRAPATHS_prepend := "${THISDIR}/${PN}:"

SRC_URI += "file://devtool-fragment.cfg \
            file://0001-Restore-cached-I2C-mux-channel.patch \
            file://0001-removed-CS-inversion.patch \
            "

