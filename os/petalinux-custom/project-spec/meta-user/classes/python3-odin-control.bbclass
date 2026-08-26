SUMMARY = "This is a recipe to build odin-control on PetaLinux from PyPI"

# Based on the pypi bbclass from langdale: https://docs.yoctoproject.org/langdale/ref-manual/classes.html#pypi-bbclass
# This ssets the URI, SECTION, HOMEPAGE, UPSTREAM_CHECK_URI, UPSTREAM_CHECK_REGEX  and CVE_PRODUCT. It will automatically
# pull from the same package name as this file, with python-/python3- stripped if necessary.

# Update the package name- this would normally come from the filename, but in our case  it needs an underscore,
# which is not allowed.
PYPI_PACKAGE = "odin_control"

# This has to be in the format expected in Yocto's license list...
LICENSE = "Apachev2"
# Get this value by running md5sum on the license file
LIC_FILES_CHKSUM = "file://LICENSE;md5=e3fc50a88d0a364313df4b21ef20c29e"

inherit pypi python_setuptools_build_meta

DEPENDS += " \
    python3-setuptools-scm-native \
    python3-toml-native \
"
