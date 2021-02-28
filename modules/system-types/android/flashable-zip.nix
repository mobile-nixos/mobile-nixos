{ config, pkgs, lib, modules, baseModules, ... }:

let
  enabled = config.mobile.system.type == "android";

  inherit (lib) types;
  inherit (config.mobile) device;
  inherit (config.system.build) android-bootimg rootfs;

  make-flashable-zip = pkgs.callPackage ./make-flashable-zip.nix {};

  # Fragments that will be re-used in the flashable zip builds

  android-flashable-fragment-assertDevice =
    if config.mobile.system.android.device_name == null then ""
    else "assert_device(${builtins.toJSON config.mobile.system.android.device_name})"
  ;

  android-flashable-fragment-burnBoot = ''
    flash_partition("boot", zip: "boot.img")
  '';

  android-flashable-fragment-burnSystem = ''
    flash_partition(${builtins.toJSON config.mobile.system.android.system_partition_destination}, zip: "system.img")
  '';

  # Flashable zips

  android-flashable-bootimg = make-flashable-zip {
    name = "flashable-${device.name}-boot.zip";
    script = ''
      ${android-flashable-fragment-assertDevice}
      ${android-flashable-fragment-burnBoot}
    '';
    copyFiles = ''
      cp -v ${android-bootimg} boot.img
    '';
  };

  android-flashable-system = make-flashable-zip {
    name = "flashable-${device.name}-boot.zip";
    script = ''
      ${android-flashable-fragment-assertDevice}
      ${android-flashable-fragment-burnSystem}
    '';
    copyFiles = ''
      cp -v ${rootfs}/${rootfs.filename} system.img
    '';
  };

  android-flashable-zip = make-flashable-zip {
    name = "flashable-${device.name}.zip";
    script = ''
      ${android-flashable-fragment-assertDevice}
      ${android-flashable-fragment-burnBoot}
      ${android-flashable-fragment-burnSystem}
    '';
    copyFiles = ''
      cp -v ${android-bootimg} boot.img
      cp -v ${rootfs}/${rootfs.filename} system.img
    '';
  };
in
{
  options = {
    mobile.system.android = {
      device_name = lib.mkOption {
        type = types.nullOr types.str;
        description = "Value of `ro.product.device` or `ro.build.product`. Used to compare against in flashable zips.";
        default = null;
        internal = true;
      };

      system_partition_destination = lib.mkOption {
        type = types.str;
        description = "Partition label on which to install the system image. E.g. change to `userdata` when it does not fit in the system partition.";
        default = "system";
        internal = true;
      };
    };
  };

  config = lib.mkMerge [
    (lib.mkIf enabled {
      system.build = {
        inherit
          android-flashable-bootimg
          android-flashable-system
          android-flashable-zip
        ;
      };
    })
  ];
}