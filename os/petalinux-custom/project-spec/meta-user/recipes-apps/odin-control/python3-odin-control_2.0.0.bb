inherit python3-odin-control

RDEPENDS:${PN} += "python3-tornado (>=6.0)"
RDEPENDS:${PN} += "python3-psutil (>=5.0)"

SRC_URI += "file://remove-build-system-requirements.patch"

SRC_URI[sha256sum] = "52f74abe94aebcdd19018894dcc343950d65e022ff68f7be4604edd472632eb3"

# Specific build tool versions for installation from the pyproject.toml
DEPENDS += " \
	python3-setuptools (>=64) \
"
