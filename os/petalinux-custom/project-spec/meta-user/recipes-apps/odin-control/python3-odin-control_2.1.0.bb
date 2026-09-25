inherit python3-odin-control

RDEPENDS:${PN} += "python3-tornado (>=6.0)"
RDEPENDS:${PN} += "python3-psutil (>=5.0)"

SRC_URI[sha256sum] = "7f2a60fa9ac99d05411cb16095ee146c2f855b448a57bbf27bb95968c9ce47d5"

# Specific build tool versions for installation from the pyproject.toml
DEPENDS += " \
	python3-setuptools (>=64) \
    python3-setuptools-scm-native (>=8) \
"
