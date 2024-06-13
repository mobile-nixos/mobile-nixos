{ config, pkgs, lib, modules, baseModules, ... }:

let
  enabled = config.mobile.system.type == "android";

  inherit (lib) mkOption types;
  inherit (config.mobile) device;
  inherit (config.mobile.outputs.generatedFilesystems) rootfs;
  inherit (config.mobile.outputs.android) android-bootimg;
  inherit (pkgs.mobile-nixos) make-flashable-zip;

  # Fragments that will be re-used in the flashable zip builds

  android-flashable-fragment-assertDevice =
    if config.mobile.system.android.device_name == null then ""
    else "assert_device(${builtins.toJSON config.mobile.system.android.device_name})"
  ;

  android-flashable-fragment-burnBoot = ''
    flash_partition(${builtins.toJSON config.mobile.system.android.boot_partition_destination}, zip: "boot.img")
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
    name = "flashable-${device.name}-system.zip";
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
    mobile = {
      outputs = {
        android = {
          android-flashable-bootimg = mkOption {
            type = types.package;
            description = ''
              `boot.img` in Android flashable zip format.
            '';
            visible = false;
          };
          android-flashable-system = mkOption {
            type = types.package;
            description = ''
              `system.img` in Android flashable zip format.
            '';
            visible = false;
          };
          android-flashable-zip = mkOption {
            type = types.package;
            description = ''
              Android flashable zip which will install `boot.img` and `system.img`.
            '';
            visible = false;
          };
        };
      };
    };
  };

  config = lib.mkMerge [
    (lib.mkIf enabled {
      mobile.outputs.android = {
        inherit
          android-flashable-bootimg
          android-flashable-system
          android-flashable-zip
        ;
      };
    })
  ];
}
