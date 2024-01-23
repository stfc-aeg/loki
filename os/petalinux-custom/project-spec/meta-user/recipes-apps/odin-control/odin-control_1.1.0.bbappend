# Temporary bbappend to force odin_control recipes to use the async_adapter branch needed for mercury support.
# Eventually when async support is merged into odin_control's master tagged revisions, this will not be required.
#
# To use this recipe, require odin-control-async.

#PACKAGES += "${PN}-async"
#SRC_URI_${PN}-async = "git://github.com/odin-detector/odin-control.git;branch=async_adapter"
#SRCREV_${PN}-async = "75210de500890a6b181433cc12dfbd5133975948"
#PV_${PN}-async = "1.0+git${SRCPV}"

SRC_URI = "git://git@github.com/odin-detector/odin-control.git;protocol=ssh"
SRCREV = "75210de500890a6b181433cc12dfbd5133975948"

# PV is not updated so that recipes that require specific versions of odin_control are not disrupted.
