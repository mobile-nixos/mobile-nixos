{ config, lib, pkgs, ... }:

let
  inherit (lib) mkOption mkMerge mkIf types;
  cfg = config.mobile.hardware.socs;
in
{
  options.mobile = {
    hardware.socs.mediatek-mt6785.enable = mkOption {
      type = types.bool;
      default = false;
      description = "enable when SOC is Mediatek MT6785 (Helio G90)";
    };
  };

  config = mkMerge [
    {
      mobile = mkIf cfg.mediatek-mt6785.enable {
        system.system = "aarch64-linux";
      };
    }
  ];
}
