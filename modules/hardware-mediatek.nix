{ config, lib, pkgs, ... }:

let
  inherit (lib) mkOption mkMerge mkIf types;
  cfg = config.mobile.hardware.socs;
  anyMediatek = lib.any (v: v) [
    cfg.mediatek-mt6755.enable
    cfg.mediatek-mt6785.enable
    cfg.mediatek-mt8127.enable
    cfg.mediatek-mt8183.enable
  ];
in
{
  options.mobile = {
    hardware.socs.mediatek-mt6755.enable = mkOption {
      type = types.bool;
      default = false;
      description = lib.mdDoc "enable when SOC is Mediatek MT6755 (Helio P10)";
    };
    hardware.socs.mediatek-mt6785.enable = mkOption {
      type = types.bool;
      default = false;
      description = lib.mdDoc "enable when SOC is Mediatek MT6785 (Helio G90)";
    };
    hardware.socs.mediatek-mt8127.enable = mkOption {
      type = types.bool;
      default = false;
      description = lib.mdDoc "enable when SOC is Mediatek MT8127";
    };
    hardware.socs.mediatek-mt8183.enable = mkOption {
      type = types.bool;
      default = false;
      description = lib.mdDoc "enable when SOC is Mediatek MT8183";
    };
  };

  config = mkMerge [
    {
      mobile = mkIf cfg.mediatek-mt6755.enable {
        system.system = "aarch64-linux";
        quirks.fb-refresher.enable = true;
      };
    }
    {
      mobile = mkIf cfg.mediatek-mt6785.enable {
        system.system = "aarch64-linux";
      };
    }
    {
      mobile = mkIf cfg.mediatek-mt8127.enable {
        system.system = "armv7l-linux";
        quirks.fb-refresher.enable = true;
        kernel.structuredConfig = [
          (helpers: with helpers; {
            ARCH_MT8127 = lib.mkDefault yes;
            ARCH_MEDIATEK = option yes;
          })
        ];
      };
    }
    {
      mobile = mkIf cfg.mediatek-mt8183.enable {
        system.system = "aarch64-linux";
      };
    }
    (mkIf anyMediatek {
      mobile.kernel.structuredConfig = [
        (helpers: with helpers; {
          ARCH_MEDIATEK = lib.mkDefault yes;
        })
      ];
    })
  ];
}
