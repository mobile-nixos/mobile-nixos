{
  device_name
}:
let
  pkgs = (import ./overlay);
in
with pkgs;
let
  device_config = import (./devices + ("/" + device_name)) {inherit pkgs lib;};
  linux = pkgs."linux_${device_name}";
  kernel = "${linux}/Image.gz-dtb";
  dt = "${linux}/boot/dt.img";

  # TODO : Allow appending / prepending
  cmdline = device_config.kernel_cmdline;

  # TODO : make configurable?
  initrd = callPackage ./rootfs.nix { inherit device_config; };
in
stdenv.mkDerivation {
  name = "nixos-mobile_${device_name}_boot.img";

  src = builtins.filterSource (path: type: false) ./.;
  unpackPhase = "true";

  buildInputs = [
    mkbootimg
    dtbTool
    linux
  ];

  installPhase = ''
    mkbootimg \
      --kernel  ${kernel} \
      --dt      ${dt} \
      --ramdisk ${initrd} \
      --cmdline       "${cmdline}" \
      --base           ${device_config.flash_offset_base   } \
      --kernel_offset  ${device_config.flash_offset_kernel } \
      --second_offset  ${device_config.flash_offset_second } \
      --ramdisk_offset ${device_config.flash_offset_ramdisk} \
      --tags_offset    ${device_config.flash_offset_tags   } \
      --pagesize       ${device_config.flash_pagesize      } \
      -o $out
  '';
}
