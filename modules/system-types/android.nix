{ config, pkgs, lib, modules, baseModules, ... }:

let
  # In the future, this pattern should be extracted.
  # We're basically subclassing the main config, just like nesting does in
  # NixOS (<nixpkgs/modules/system/activation/top-level.nix>)
  # Here we're only adding the `is_recovery` option.
  # In the future, we may want to move the recovery configuration to a file.
  recovery = (import ../../lib/eval-config.nix {
    inherit baseModules;
    modules = modules ++ [{
      mobile.boot.stage-1.bootConfig = {
        is_recovery = true;
      };
    }];
  }).config;

  device_config = config.mobile.device;
  device_name = device_config.name;
  enabled = config.mobile.system.type == "android";

  inherit (config.system.build) rootfs;

  android-recovery = pkgs.callPackage ../../systems/bootimg.nix {
    inherit device_config;
    initrd = recovery.system.build.initrd;
    name = "recovery.img";
  };

  android-bootimg = pkgs.callPackage ../../systems/bootimg.nix {
    inherit device_config;
    initrd = config.system.build.initrd;
  };

  android-device = pkgs.runCommandNoCC "android-device-${device_name}" {} ''
    mkdir -p $out
    ln -s ${rootfs}/${rootfs.filename} $out/system.img
    ln -s ${android-bootimg} $out/boot.img
    ln -s ${android-recovery} $out/recovery.img
  '';
in
{
  config = lib.mkMerge [
    { mobile.system.types = [ "android" ]; }

    (lib.mkIf enabled {
      system.build = {
        inherit android-bootimg android-recovery android-device;
        mobile-installer = throw "No installer yet...";
      };
    })
  ];
}
