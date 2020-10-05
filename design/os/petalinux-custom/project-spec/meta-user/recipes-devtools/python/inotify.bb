SUMMARY = "inotify, not pyinotify"

SRC_URI = "git://github.com/dsoprea/PyInotify.git"
SRCREV = "0.2.10"
LICENSE = "GPLv2"
LIC_FILES_CHKSUM = "file://LICENSE;md5=8c16666ae6c159876a0ba63099614381"

inherit setuptools3

S = "${WORKDIR}/git/"
