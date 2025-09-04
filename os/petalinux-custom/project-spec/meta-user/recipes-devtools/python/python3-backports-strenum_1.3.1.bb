SUMMARY = "A backport of (copy and paste from) python 3.11’s StrEnum class for >=3.8.6"
HOMEPAGE = "https://github.com/clbarnes/backports.strenum"

#DEPENDS = "python3-pytest-runner-native"

SRC_URI[sha256sum] = "77c52407342898497714f0596e86188bb7084f89063226f4ba66863482f42414"

PYPI_PACKAGE = "backports.strenum"

# Manually specify the filename as it contains an underscore as opposed to the package name
PYPI_SRC_URI = "https://files.pythonhosted.org/packages/source/b/${PYPI_PACKAGE}/backports_strenum-${PV}.${PYPI_PACKAGE_EXT}"

# The license location also has to be corrected to this install directory
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${WORKDIR}/backports_strenum-${PV}/LICENSE;md5=33223c9ef60c31e3f0e866cb09b65e83"

#inherit pypi python_setuptools_build_meta
inherit pypi python_poetry_core

# The pyproject.toml is downloaded here
S = "${WORKDIR}/backports_strenum-${PV}"
