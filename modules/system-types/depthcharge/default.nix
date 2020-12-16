{ config, pkgs, lib, ... }:

let
  enabled = config.mobile.system.type == "depthcharge";

  inherit (lib) types;
  inherit (config.system.build) stage-0;
  inherit (stage-0.mobile.boot.stage-1) kernel;

  build = pkgs.callPackage ./depthcharge-build.nix {
    inherit (config.mobile.system.depthcharge.kpart) dtbs;
    device_name = config.mobile.device.name;
    initrd = stage-0.system.build.initrd;
    system = config.system.build.rootfs;
    cmdline = lib.concatStringsSep " " config.boot.kernelParams;
    kernel = kernel.package;
    arch = lib.strings.removeSuffix "-linux" config.mobile.system.system;
  };
in
{
  options = {
    mobile.system.depthcharge = {
      kpart = {
        dtbs = lib.mkOption {
          type = types.path;
          default = null;
          description = "Path to a directory with device trees, to be put in the kpart image";
          internal = true;
        };
      };
    };
  };

  config = lib.mkMerge [
    { mobile.system.types = [ "depthcharge" ]; }

    (lib.mkIf enabled {
      system.build = {
        inherit (build) disk-image kpart;
        default = build.disk-image;
      };
    })
  ];
}
