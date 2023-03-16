{ config, pkgs, lib, ... }:

let
  enabled = config.mobile.system.type == "depthcharge";

  inherit (lib) types;
  inherit (config.mobile.outputs) stage-0;
  inherit (stage-0.mobile.boot.stage-1) kernel;

  build = pkgs.callPackage ./depthcharge-build.nix {
    inherit (config.mobile.system.depthcharge.kpart) dtbs;
    device_name = config.mobile.device.name;
    inherit (config.mobile.outputs) initrd;
    system = config.mobile.outputs.generatedFilesystems.rootfs;
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
    mobile = {
      outputs = {
        depthcharge = {
          disk-image = lib.mkOption {
            type = types.package;
            description = lib.mdDoc ''
              Full Mobile NixOS disk image for a depthcharge-based system.
            '';
            visible = false;
          };
          kpart = lib.mkOption {
            type = types.package;
            description = lib.mdDoc ''
              Kernel partition for a depthcharge-based system.
            '';
            visible = false;
          };
        };
      };
    };
  };

  config = lib.mkMerge [
    { mobile.system.types = [ "depthcharge" ]; }

    (lib.mkIf enabled {
      mobile.outputs = {
        default = build.disk-image;
        depthcharge = {
          inherit (build) disk-image kpart;
        };
      };
    })
  ];
}
