FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

# Override default files with custom ones.
#     - dropbear.default
#         - Prevent root login via ssh
#         - Update locations of generated host keys to non-volatile eMMC
#         - Add a host key location for ECDSA
#     - dropbear@.service
#         - Start service with both RSA and ECDSA keys
#     - dropbearkey.service
#         - Key generation only takes place if the key dir on eMMC is empty
#         - Keys are generated for both ECDSA and RSA
#         - Keys are generated in /tmp, then copied (limitation of key tool)
#         - Updated key generation for both types to generate to /tmp, then copy over
#           to the eMMC; for some reason, dropbearkey cannot generate directly into
#           the eMMC, potentially due to filesystem type issues.
