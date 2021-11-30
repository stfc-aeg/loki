# loki
LOKI detector system embedded controller 

## Contents
1. [Building](#building)
2. [Flashing a New Image](#flashing-a-new-image)
    - [Booting Directly form SD](#booting-directly-from-sd)
    - [Flashing eMMC or QSPI Flash from SD](#flashing-emmc-or-qspi-flash-from-sd)
    - [Flashing eMMC or SD with SCP](#flashing-emmc-or-sd-with-scp)

## Building
### Building The HW
#TODO

### Building the FSBL and PMUFW
#TODO

### Building PetaLinux
Change directory into the PetaLinux project directory:
```bash
$ cd os/petalinux-custom/
```

Run the auto-build script.
The first time this is run, you will need to import the software and hardware that has just been built:
```bash
$ ./autobuild.sh --xsa --sw
```

On successive builds, these flags are not needed.
Build products will appear in `images/linux/`.

## Flashing a New Image
The method for flashing will depend on what is currently installed on the system, and the media on which the installation should appear.
Generally speaking, the aim will be to boot from SD (if another image is not available), and copy that installation (or another) to the desired location.

Relevant Files:
- BOOT.BIN: Packaged boot binary file containing:
	- u-boot.elf (u-boot binary)
	- fsbl.elf (FSBL)
	- pmufw.elf (PMUFW)
	- system.bit
	- bl31.elf
	- system.dtb (device tree)
- boot.scr: Boot script 
- image.ub: FIT image containing:
	- Kernel
	- RootFS
	- Ramdisk (if used)

Note that most of these steps will need to be performed via the FTDI/USB interface at 115200 baud, unless using the network SCP methods where an image is already present and accessible remotely.

### Booting Directly From SD
Booting from SD is the simplest method, and is typically the easiest to use when initially debugging a system, particularly when not networked.
There is no need to have any image on the board to do this.

1. Copy the three required files (`BOOT.BIN`, `boot.scr` and `image.ub`) onto the SD card.
2. Insert the SD Card
3. Change the boot mode dip switches to SD boot (on Trenz carrier, S5-1 and S5-2 should both be ON)
4. Power cycle the system if the dip switches were changed.

### Flashing eMMC or QSPI Flash from SD
The easiest method is to boot the image you are flashing on the SD, and using it to flash itself onto other media.
This is also the only method if there is currently no image on the board.
If there is already an image running on the board, consider using [SCP](#flashing-emmc-or-sd-with-scp).

#### Flashing eMMC from SD
The eMMC behaves exactly the same as the SD card (as it is currently configured).

1. Boot to the new SD image as described [above](#booting-directly-from-sd)
2. Copy the files from SD to eMMC:
	```bash
	# cp /mnt/sd-mmcblk1p0/* /mnt/sd-mmcblk0p0/
	```
3. Set the dip switches to boot eMMC (S5-1 OFF, S5-2 ON_)
4. Power cycle the system

If you are just updating the system and the U-Boot script and binary have not changed, you may not need to flash anything other than the kernel.

From this point, if the new image is booted, the SD can be removed, programmed, and files copied to the eMMC without changing the boot device.
Simply reboot the device at the command line to boot the new image.

#### Flashing QSPI Flash from SD
The QSPI Flash does not have a filesystem, and so the image cannot just be copied.
Instead, the `flashcp` command must be used.

1. Boot to the new SD image as described [above](#booting-directly-from-sd)
2. List the flash partitions and verify that `boot`, `bootscr` and `kernel` are seen:
	```bash
	root@petalinux-custom:~# cat /proc/mtd           
	dev:    size   erasesize  name   
	mtd0: 00400000 00002000 "boot"   
	mtd1: 00040000 00002000 "bootenv"
	mtd2: 03200000 00002000 "kernel" 
	mtd3: 00008000 00002000 "bootscr"
	```
3. Flash the `kernel` partition with the `image.ub` FIT file by using the `flashcp` command on the `mtd` partition labelled `kernel`. In this case, it is listed above as `mtd2`:
	```bash
	root@petalinux-custom:~# flashcp -v /mnt/sd-mmcblk1p0/image.ub /dev/mtd2
	```
4. Repeat the process for `BOOT.BIN` into the partition labelled `boot`, and `boot.scr` into the partition labelled `bootscr`.
5. Check that the dip switches are set to SD/QSPI (S5-1 ON, S5-2 ON), and remove the SD card.
6. Reboot the system with the `reboot` command.

If you are just updating the system and the U-Boot script and binary have not changed, you may not need to flash anything other than the kernel.

### Flashing eMMC or SD with SCP
If your board already has an image being run from SD/eMMC/QSPI with network access, you can simplify the process by using `scp` to copy the files directly onto the SD/eMMC card and rebooting.
Note that to flash the SD from a QSPI boot, you will have to have the system running before the SD is inserted, or it will attempt to boot from the empty SD and fail silently.

For SD, use device `/mnt/sd-mmcblk1p1/`, and for eMMC use `/mnt/sd-mmcblk0p1/`:
```bash
$ scp BOOT.BIN root@<zynq-ip>:/mnt/sd-mmcblk1p1/
$ scp boot.scr root@<zynq-ip>:/mnt/sd-mmcblk1p1/
$ scp image.ub root@<zynq-ip>:/mnt/sd-mmcblk1p1/
```

If the device already has the desired boot device selected with the dip switches (or has not changed), you can simply use `reboot` to boot the new image.
If you are going to be booting from a different device, set the dip switches and power cycle.

### Flashing QSPI Flash with SCP
The QSPI Flash does not have a filesystem, so is a little more involved to flash.

Use `scp` to copy files to directory on the zynq, then use the `flashcp` command as shown [above](#flashing-qspi-flash-from-sd) with source locations updated accordingly.

If the device already has the desired boot device selected with the dip switches (or has not changed), you can simply use `reboot` to boot the new image.
If you are going to be booting from a different device, set the dip switches and power cycle.

### Quick Note on Split Installs and Multiple Boot Devices
Note that if multiple media types have installed images, it may be difficult to tell which of them has booted; the physically selected boot device may not be the device that's FIT image has been used.
Whether this is relevant is quite application-specific.

The system only needs one up to date BOOT.BIN. which will be located within the device chosen by the dip switches.
From here, the list of `boot_targets` configured in the U-Boot environment (also stored in `BOOT.BIN` will be cycled through looking for a valid `boot.scr`, always starting with the current device.
Once a valid `boot.scr` is found, U-boot will attempt to boot its `image.ub` FIT image.

For example, this means that the system could have a single `BOOT.BIN` installed on QSPI Flash without a kernel image, designed to boot an image on eMMC.
In this case, updating the kernel image (so long as U-boot or any other part of `BOOT.BIN` had not changed)_ would involve overwriting `image.ub` on eMMC only.
However, changes to the `BOOT.BIN` would need to be overwritten on the QSPI Flash...

**The best method to debug what is going on is via the FTDI USB interface, which can be used to view the U-Boot output at boot.
If the boot is interrupted with a key press, you can also manually edit the `boot__targets` with `setenv`, and force boot a different device by the calling `run bootcmd`**.
