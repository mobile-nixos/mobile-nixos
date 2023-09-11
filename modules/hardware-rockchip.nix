{ config, lib, ... }:

let
  inherit (lib)
    mkIf
    mkMerge
    mkOption
    types
  ;
  cfg = config.mobile.hardware.socs;
  anyRockchip = lib.any (v: v) [
    cfg.rockchip-op1.enable
  ];
in
{
  options.mobile = {
    hardware.socs.rockchip-op1.enable = mkOption {
      type = types.bool;
      default = false;
      description = lib.mdDoc "enable when SOC is RK3399-OP1";
    };
  };

  config = mkMerge [
    {
      mobile = mkIf cfg.rockchip-op1.enable {
        system.system = "aarch64-linux";
      };
    }
    (mkIf anyRockchip {
      mobile.kernel.structuredConfig = [
        (helpers: with helpers; {
          ARCH_ROCKCHIP = lib.mkDefault yes;
        })
      ];
    })
  ];
}
