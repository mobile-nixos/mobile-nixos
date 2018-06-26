{
  device_config,
  initrd
}:
let
  pkgs = (import ../overlay);
  inherit (pkgs) buildPackages;
in
let
  device_name = device_config.name;
  device_info = device_config.info;
  linux = device_info.kernel;
  kernel = "${linux}/Image.gz-dtb";
  dt = "${linux}/boot/dt.img";

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

  buildInputs = [
    linux
  ];

  installPhase = ''
    mkbootimg \
      --kernel  ${kernel} \
      --dt      ${dt} \
      --ramdisk ${initrd} \
      --cmdline       "${cmdline}" \
      --base           ${device_info.flash_offset_base   } \
      --kernel_offset  ${device_info.flash_offset_kernel } \
      --second_offset  ${device_info.flash_offset_second } \
      --ramdisk_offset ${device_info.flash_offset_ramdisk} \
      --tags_offset    ${device_info.flash_offset_tags   } \
      --pagesize       ${device_info.flash_pagesize      } \
      -o $out
  '';
}
