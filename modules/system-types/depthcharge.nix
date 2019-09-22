{ config, pkgs, lib, ... }:

let
  device_config = config.mobile.device;
  enabled = config.mobile.system.type == "depthcharge";

  disk-image = pkgs.callPackage ../../systems/depthcharge {
    inherit device_config;
    initrd = config.system.build.initrd;
    system = config.system.build.rootfs;
  };
in
{
  config = lib.mkMerge [
    { mobile.system.types = [ "depthcharge" ]; }

    (lib.mkIf enabled {
      system.build = {
        inherit disk-image;
        # installer shortcut; it's a depthcharge disk-image build.
        mobile-installer = disk-image;
      };
    })
  ];
}
