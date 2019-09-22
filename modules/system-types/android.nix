{ config, pkgs, lib, ... }:

let
  device_config = config.mobile.device;
  device_name = device_config.name;
  enabled = config.mobile.system.type == "android";

  inherit (config.system.build) rootfs;

  android-bootimg = pkgs.callPackage ../../systems/bootimg.nix {
    inherit device_config;
    initrd = config.system.build.initrd;
  };

  android-device = pkgs.runCommandNoCC "android-device-${device_name}" {} ''
    mkdir -p $out
    ln -s ${rootfs}/${rootfs.filename} $out/system.img
    ln -s ${android-bootimg} $out/boot.img
  '';
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
