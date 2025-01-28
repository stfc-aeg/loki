# loki
LOKI detector system embedded controller 
 
For detailed documentation, see the [LOKI Wiki](https://github.com/stfc-aeg/loki/wiki/)

This repository is designed to either:
1. Build an application-specific LOKI image when used as a submodule
2. Build the recovery image (typically destined for module flash, and used for self-test / commissioning)

## Repository Contents
- `share`, `config.mk`, `Makefile.in`, `configure.ac`: Automatic configuration of the project based on hardware selection, application-specific configuration and application hardware/software layers.
- `design`: The firmware and low-level software design project, used for linking the software processing system to package pins, and including application-specific hardware designs.
- `os`: The PetaLinux Embedded Linux project, used for building the final system image and providing configuration and all software dependencies for odin-control based detector systems.
- `loki-recovery`, `MakefileRecovery`: Serves as a base and example application configuration, which builds an image with some self-test capability.

## Building the recovery image
The recovery image uses a standalone makefile -`MakefileRecovery`- that will build the project without being a submodule.

To build the image:
```bash
make -f MakefileRecovery
```

The image outputs will be built to `os/petalinux-custom/images/linux/`.
To upload these files to a board, see [Booting, Configuring and Updating Systems](https://github.com/stfc-aeg/loki/wiki/Booting-Updating-Debugging-and-Configuring-LOKI-Systems).

## Create an Application Project with LOKI as a Submodule
See the [LOKI Wiki](https://github.com/stfc-aeg/loki/wiki/Guidance-on-LOKI-Project-Toplevel-Design#creating-an-application-project-with-loki-as-a-submodule)
