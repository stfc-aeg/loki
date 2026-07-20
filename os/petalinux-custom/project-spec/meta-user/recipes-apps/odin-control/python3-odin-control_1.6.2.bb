inherit python3-odin-control

RDEPENDS:${PN} += "python3-setuptools"
RDEPENDS:${PN} += "python3-tornado (>=4.3)"
RDEPENDS:${PN} += "python3-fcntl"
RDEPENDS:${PN} += "python3-future"
RDEPENDS:${PN} += "python3-pyzmq (>=17.1.0)"
RDEPENDS:${PN} += "python3-psutil (>=5.0)"

SRC_URI[sha256sum] = "b159dbdcd6427105e0a35a0e56b9cb96639ccb84c92d466ab8ffffefb5a537f3"
