AC_INIT(loki, 1.0)

AC_ARG_VAR(blockdesign_override_dir, [Optional, advanced: Build using an out-of-tree version of the block design, with path o block design .bd file specified here. Consider using custom constraints first. Not yet implemented.])

AC_ARG_VAR(os_path, [Optional, advanced: Build using an out-of-tree version of petalinux, with path to PL_ROOT specified here. Consider using a custom user layer with yocto_user_layer_0 first.])

AC_ARG_VAR(platform_module_shortname, [Required: Shortname of the Trenz module used for the build. See loki/design/board_files/TE080x_board_files.csv for full list.])

AC_ARG_VAR(platform_carrier, [Required: Name of the carrier board to be used. Choose from: tebf0808])

# If left blank, will default to not including layer, which is fine.
AC_ARG_VAR(yocto_user_layer_0, [Optional: Absolute path to yocto recipe layer for application-specifics. Will be included automatically. Do not set to not include a layer.])

AC_ARG_VAR(yocto_tmpdir, [Optional, but recommended: Absolute TMPDIR location for Yocto build, not on NTFS. Required.])

AC_CONFIG_FILES([
 Makefile
 design/Makefile
 design/design_basic_settings.sh
 os/petalinux-custom/Makefile
 os/petalinux-custom/project-spec/configs/config
 ])

AC_OUTPUT
