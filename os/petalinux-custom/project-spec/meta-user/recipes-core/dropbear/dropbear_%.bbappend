FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

# Override default files with custom ones.
#     - dropbear.default
#         - Prevent root login via ssh
#         - Update locations of generated host keys to non-volatile eMMC
#         - Add a host key location for ECDSA
#     - init
#         - Add ECDSA host key generation to above location
#         - Specify using ECDSA host key on daemon start
#         - Updated key generation for both types to generate to /tmp, then copy over
#           to the eMMC; for some reason, dropbearkey cannot generate directly into
#           the eMMC, potentially due to filesystem type issues.

