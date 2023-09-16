{ config, lib, pkgs, ... }:

let
  inherit (lib) mkMerge mkOption mkIf types;
  cfg = config.mobile.hardware.socs;
  anyExynos = lib.any (v: v) [
    cfg.exynos-7880.enable
  ];
in
{
  options.mobile = {
    hardware.socs.exynos-7880.enable = mkOption {
      type = types.bool;
      default = false;
      description = lib.mdDoc "enable when SOC is Exynos 7880";
    };
  };

  config = mkMerge [
    {
      mobile = mkIf cfg.exynos-7880.enable {
        system.system = "aarch64-linux";
        quirks.fb-refresher.enable = true;
      };
    }
    (mkIf anyExynos {
      mobile.kernel.structuredConfig = [
        (helpers: with helpers; {
          ARCH_EXYNOS = lib.mkDefault yes;
        })
      ];
    })
  ];
}
