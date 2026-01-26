function mtd_label_to_device() {
	# Convert from a label like 'kernel' to '/dev/mtd2'
    # su is used because only root has access to lsmtd
	echo /dev/$(su root -c "lsmtd -r" | grep "$1 " | cut -d' ' -f 1)
	return 0
}

function mmc_name_to_mountpoint() {
	devname=$(echo $1 | awk '{print tolower($0)}')
	if [ "$devname" = "emmc" ] ; then
		echo '/mnt/emmc'
		return 0
	fi
	if [ "$devname" = "sd" ] ; then
		echo '/mnt/sd'
		return 0
	fi
	return 1
}

