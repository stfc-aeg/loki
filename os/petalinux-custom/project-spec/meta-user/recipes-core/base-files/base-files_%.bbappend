DESCRIPTION = "Allows to customize the fstab"
PR = "r0"

do_install_append(){
    # Create the mountpoint
    mkdir ${D}/mnt/flashmtd1

    # Add fstab entry for jffs2 filesystem mount for mtd flash 'bootenv' partition
    echo "/dev/mtdblock1       /mnt/flashmtd1          jffs2           rw      0  0" >> ${D}${sysconfdir}/fstab
}
