{ config, lib, pkgs, ... }:

let
  inherit (lib) mkIf mkMerge mkOption types;
  cfg = config.mobile.hardware.socs;
in
{
  options.mobile = {
    hardware.socs.rockchip-op1.enable = mkOption {
      type = types.bool;
      default = false;
      description = "enable when SOC is RK3399-OP1";
    };
    hardware.socs.rockchip-rk3399s.enable = mkOption {
      type = types.bool;
      default = false;
      description = "enable when SOC is RK3399";
    };
  };

  config = mkMerge [
    {
      mobile = mkIf cfg.rockchip-op1.enable {
        system.system = "aarch64-linux";
      };
    }
    {
      mobile = mkIf cfg.rockchip-rk3399s.enable {
        system.system = "aarch64-linux";
      };
    }
  ];
}
