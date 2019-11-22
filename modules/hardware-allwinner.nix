{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.mobile.hardware.socs;
in
{
  options.mobile = {
    hardware.socs.allwinner-r18.enable = mkOption {
      type = types.bool;
      default = false;
      description = "enable when SOC is Allwinner-R18";
    };
  };

  config = mkMerge [
    {
      mobile = mkIf cfg.allwinner-r18.enable {
        system.system = "aarch64-linux";
        quirks.u-boot.soc.family = "allwinner";
      };
    }
  ];
}
