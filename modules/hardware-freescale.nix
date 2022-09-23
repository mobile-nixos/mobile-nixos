{ config, lib, pkgs, ... }:

let
  inherit (lib) mkIf mkMerge mkOption types;
  cfg = config.mobile.hardware.socs;
in
{
  options.mobile = {
    hardware.socs.freescale-imx6sll.enable = mkOption {
      type = types.bool;
      default = false;
      description = "enable when SOC is Freescale i.MX 6SLL";
    };
  };

  config = mkMerge [
    {
      mobile = mkIf cfg.freescale-imx6sll.enable {
        system.system = "armv7l-linux";
      };
    }
  ];
}
