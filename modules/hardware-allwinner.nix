{ config, lib, pkgs, ... }:

let
  inherit (lib) mkIf mkMerge mkOption types;
  inherit (pkgs) imageBuilder;
  cfg = config.mobile.hardware.socs;
  initialGapSize = 
    # Start of the "magic" location bs=1024 seek=8
    (imageBuilder.size.MiB 8) +
    # Current u-boot size: 483K, so let's leave a *bunch* of room.
    (imageBuilder.size.MiB 2)
  ;
in
{
  options.mobile = {
    hardware.socs.allwinner-a64.enable = mkOption {
      type = types.bool;
      default = false;
      description = "enable when SOC is Allwinner A64";
    };
    hardware.socs.allwinner-r18.enable = mkOption {
      type = types.bool;
      default = false;
      description = "enable when SOC is Allwinner-R18";
    };
  };

  config = mkMerge [
    {
      mobile = mkIf cfg.allwinner-a64.enable {
        system.system = "aarch64-linux";
        quirks.u-boot = {
          soc.family = "allwinner";
          inherit initialGapSize;
        };
      };
    }
    {
      mobile = mkIf cfg.allwinner-r18.enable {
        system.system = "aarch64-linux";
        quirks.u-boot = {
          soc.family = "allwinner";
          inherit initialGapSize;
        };
      };
    }
  ];
}
