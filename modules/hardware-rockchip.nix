{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.mobile.hardware.socs;
in
{
  options.mobile = {
    hardware.socs.rockchip-rk3399.enable = mkOption {
      type = types.bool;
      default = false;
      description = "enable when SOC is RK3399";
    };
    hardware.socs.rockchip-op1.enable = mkOption {
      type = types.bool;
      default = false;
      description = "enable when SOC is RK3399-OP1";
    };
  };

  config = mkMerge [
    {
      mobile = mkIf cfg.rockchip-op1.enable {
        system.system = "aarch64-linux";
      };
    }
    {
      mobile = mkIf cfg.rockchip-rk3399.enable {
        system.system = "aarch64-linux";
        quirks.u-boot.soc.family = "rockchip";
      };
    }
  ];
}
