{
  device_name ? "asus-z00t"
}:
with (import ./overlay);

let
  # TODO : import this from device description
  linux = pkgs."linux_${device_name}";
  kernel = "${linux}/Image.gz-dtb";
  dt = "${linux}/boot/dt.img";
  cmdline = "androidboot.hardware=qcom ehci-hcd.park=3 androidboot.bootdevice=7824900.sdhci lpm_levels.sleep_disabled=1 androidboot.selinux=permissive";
  ramdisk = callPackage ./rootfs.nix { inherit device_name; };

  base           = "0x10000000";
  kernel_offset  = "0x00008000";
  second_offset  = "0x00f00000";
  ramdisk_offset = "0x02000000";
  tags_offset    = "0x00000100";
  pagesize       = "2048";


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
      --ramdisk ${ramdisk} \
      --cmdline "${cmdline}" \
      --base           ${base          } \
      --kernel_offset  ${kernel_offset } \
      --second_offset  ${second_offset } \
      --ramdisk_offset ${ramdisk_offset} \
      --tags_offset    ${tags_offset   } \
      --pagesize       ${pagesize      } \
      -o $out
  '';
}
