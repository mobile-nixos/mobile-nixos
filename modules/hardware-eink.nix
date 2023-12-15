{ config, lib, pkgs, ... }:

let
  inherit (lib)
    mkIf
    mkOption
  ;
  cfg = config.mobile.hardware.eink;
in
{
  options.mobile.hardware.eink = {
    enable = mkOption {
      default = false;
      description = lib.mdDoc ''
        Enable to change some defaults so they work better on an eink display.
      '';
    };
    enableEinkTheme = mkOption {
      default = cfg.enable;
      description = lib.mdDoc ''
        Enable only the eink changes affecting the theme.
      '';
    };
  };
  config = mkIf cfg.enableEinkTheme {
    boot.kernelParams = [
      # Black on white fbcon
      "vt.default_red=0xFF,0xBC,0x4F,0xB4,0x56,0xBC,0x4F,0x00,0xA1,0xCF,0x84,0xCA,0x8D,0xB4,0x84,0x68"
      "vt.default_grn=0xFF,0x55,0xBA,0xBA,0x4D,0x4D,0xB3,0x00,0xA0,0x8F,0xB3,0xCA,0x88,0x93,0xA4,0x68"
      "vt.default_blu=0xFF,0x58,0x5F,0x58,0xC5,0xBD,0xC5,0x00,0xA8,0xBB,0xAB,0x97,0xBD,0xC7,0xC5,0x68"
    ];

    # Why not use `logo.svg`?
    # It's because it's not pure black, it has blue.
    # Let's use a pure black logo for eink!
    mobile.boot.stage-1.gui.logo = pkgs.runCommand "logo.eink.svg" {} ''
      sed -e 's/#ffffff/#000000/g' ${../artwork/logo/logo.white.svg} > $out
    '';

    # With this one, we have to switch colours around!
    mobile.boot.stage-1.kernel.logo.logo = pkgs.runCommand "kernel-logo.eink.svg" {} ''
      sed \
        -e 's/#ffffff/#xxxxxx/g' \
        -e 's/#000000/#ffffff/g' \
        -e 's/#xxxxxx/#000000/g' \
        ${../artwork/boot-logo.svg} > $out
    '';

    mobile.boot.stage-1.bootConfig = {
      splash = {
        theme = "mono";
        background = "0xFFFFFFFF";
        foreground = "0xFF000000";
      };
    };
  };
}
