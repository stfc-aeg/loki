DESCRIPTION = "Allows to customize the fstab"
PR = "r0"

do_install:append(){
    # Create the mountpoint
    mkdir ${D}/mnt/flashmtd1

    # Add fstab entry for jffs2 filesystem mount for mtd flash 'bootenv' partition
    echo "/dev/mtdblock1       /mnt/flashmtd1          jffs2           rw,nofail      0  0" >> ${D}${sysconfdir}/fstab

    # Add fstab entry for MMC cards (SD and eMMC) with friendlier names. Systemd should create the directories.
    echo "/dev/mmcblk0p1       /mnt/emmc          auto       defaults,auto,nofail  0  0" >> ${D}${sysconfdir}/fstab

    echo "/dev/mmcblk1p1       /mnt/sd          auto       defaults,auto,nofail  0  0" >> ${D}${sysconfdir}/fstab

}
