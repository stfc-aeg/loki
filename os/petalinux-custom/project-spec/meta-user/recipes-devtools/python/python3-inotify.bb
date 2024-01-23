SUMMARY = "inotify, not pyinotify"
HOMEPAGE = "https://pypi.org/project/inotify/"

# It appears that the license file is not present in the .tar.gz downloaded by pypi
#LICENSE = "GPLv2"
#LIC_FILES_CHKSUM = "file://LICENSE;md5=8c16666ae6c159876a0ba63099614381"
LICENSE = "CLOSED"

PYPI_PACKAGE = "inotify"

PV = "0.2.10"
SRC_URI[md5sum] = "33c7ee4a7cde60036a2d2a1a55c7c7c8"

inherit pypi setuptools3
