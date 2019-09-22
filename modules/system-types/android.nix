{ config, pkgs, lib, ... }:

let
  device_config = config.mobile.device;
  enabled = config.mobile.system.type == "android";

  android-bootimg = pkgs.callPackage ../../systems/bootimg.nix {
    inherit device_config;
    initrd = config.system.build.initrd;
  };

  android-device = pkgs.callPackage ../../systems/android-device.nix {
    inherit config;
  };
in
{
  config = lib.mkMerge [
    { mobile.system.types = [ "android" ]; }

    (lib.mkIf enabled {
      system.build = {
        inherit android-bootimg android-device;
        mobile-installer = throw "No installer yet...";
      };
    })
  ];
}
