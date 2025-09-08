SUMMARY = "py-uio by mvduin - Userspace IO in Python"
HOMEPAGE = "https://github.com/mvduin/py-uio"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://LICENSE;md5=793e45592d51598b134b3825c5071844"

SRC_URI = "git://github.com/mvduin/py-uio.git;protocol=https;branch=master"

SRCREV = "332ad1669785faa29f4cfc1ff35c463a73794c17"

inherit setuptools3

S = "${WORKDIR}/git"
