{
  device_name
}:
with (import ./overlay);

let
  deviceinfo = (lib.importJSON ./devices/postmarketOS-devices.json).${device_name};
  linux = pkgs."linux_${device_name}";
  kernel = "${linux}/Image.gz-dtb";
  dt = "${linux}/boot/dt.img";

  # TODO : Allow appending / prepending
  cmdline = deviceinfo.kernel_cmdline;

  # TODO : make configurable?
  initrd = callPackage ./rootfs.nix { inherit device_name; };
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
      --base           ${deviceinfo.flash_offset_base   } \
      --kernel_offset  ${deviceinfo.flash_offset_kernel } \
      --second_offset  ${deviceinfo.flash_offset_second } \
      --ramdisk_offset ${deviceinfo.flash_offset_ramdisk} \
      --tags_offset    ${deviceinfo.flash_offset_tags   } \
      --pagesize       ${deviceinfo.flash_pagesize      } \
      -o $out
  '';
}
