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

## Building an Application Image with LOKI as a Submodule
1. Create your application directory / repository
#TODO
```bash
```

2. Add LOKI as a submodule
#TODO
```bash
```

3. Create a basic application configuration using `loki-recovery` as a reference:

Copy the base configuration environment files to your top-level directory.
```bash
cp ./loki/loki-recovery/machine.env.example ./
cp ./loki/loki-recovery/repo.env ./
```

Create new blank constraints and Yocto layer directories (your choice of name for the Yocto layer).
```bash
mkdir constraints
mkdir meta-<whatever>
```

Update the `repo.env` Yocto layer location to match `meta-<whatever>`.
If your application does not require a custom Yocto layer, just delete the line that defines `yocto_user_layer_0`.

Copy the Application makefile from recovery to be the default application directory makefile:
```bash
cp ./loki/MakefileRecovery ./Makefile
```

Update the Makefile to suit your application:
- Set `LOKI_DIR` to the submodule location, most likely `./loki/`
- Set `APPLICATION_DIR` to the location of your `.env` files, most likely `./`

4. Populate your application-specifics
	- Add any constraints to the `constraints` directory in a file with name `_l_<whatever>.xdc
	- If using one, define a Yocto layer in `meta-<whatever>`. See [Odin Control Yocto Layer Creation](https://github.com/stfc-aeg/loki/wiki/Yocto-Layer-for-Odin-Control) for more information.

5. Build the project
```bash
make
```
