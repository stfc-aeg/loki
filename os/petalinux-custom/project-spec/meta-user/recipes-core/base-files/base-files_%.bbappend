DESCRIPTION = "Allows to customize the fstab"
PR = "r0"

do_install_append(){
    # Create the mountpoint
    mkdir ${D}/mnt/flashmtd1

    # Add fstab entry for jffs2 filesystem mount for mtd flash 'bootenv' partition
    echo "/dev/mtdblock1       /mnt/flashmtd1          jffs2           rw      0  0" >> ${D}${sysconfdir}/fstab

    # Bind mount the eMMC network interfaces directory (if present) to the sourced directory created in init-ifupdown
    echo "/mnt/sd-mmcblk0p1/interfaces-mmc /etc/network/interfaces-mmc none bind,nofail 0 0" >> ${D}${sysconfdir}/fstab
}
