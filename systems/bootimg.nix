{ device_config
, initrd
, pkgs
}:
let
  inherit (pkgs) buildPackages;
  inherit (device_info) kernel dtb;
  device_name = device_config.name;
  device_info = device_config.info;

  with_qcdt = device_info ? bootimg_qcdt && device_info.bootimg_qcdt;
  kernel_file = if device_info ? kernel_file then device_info.kernel_file else "${kernel}/${kernel.file}";

  # TODO : Allow appending / prepending
  cmdline = device_info.kernel_cmdline;
in
pkgs.stdenv.mkDerivation {
  name = "nixos-mobile_${device_name}_boot.img";

  src = builtins.filterSource (path: type: false) ./.;
  unpackPhase = "true";

  nativeBuildInputs = [
    buildPackages.mkbootimg
    buildPackages.dtbTool
  ];

  installPhase = ''
	echo Using kernel: ${kernel_file}
(
PS4=" $ "
set -x
    mkbootimg \
      --kernel  ${kernel_file} \
      ${
        if with_qcdt then
          "--dt ${dtb}"
        else
          ""
      } \
      --ramdisk ${initrd} \
      --cmdline       "${cmdline}" \
      --base           ${device_info.flash_offset_base   } \
      --kernel_offset  ${device_info.flash_offset_kernel } \
      --second_offset  ${device_info.flash_offset_second } \
      --ramdisk_offset ${device_info.flash_offset_ramdisk} \
      --tags_offset    ${device_info.flash_offset_tags   } \
      --pagesize       ${device_info.flash_pagesize      } \
      -o $out
)
  '';
}
