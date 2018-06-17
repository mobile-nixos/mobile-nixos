{ config, lib, pkgs, ... }:

with lib;
with import ./initrd-order.nix;

let
  cfg = config.mobile.boot.stage-1.splash;
in
{
  options.mobile.boot.stage-1.splash = {
    enable = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Enables splash screen.
      '';
    };
  };

  config.mobile.boot.stage-1 = lib.mkIf cfg.enable {
    init = lib.mkOrder AFTER_FRAMEBUFFER_INIT ''
      show_splash() {
        echo | fbv -cafei /$1.png > /dev/null 2>&1
      }

      show_splash loading
    '';
    extraUtils = [
      pkgs.fbv
    ];
    contents = [
      { object = ../loading.png; symlink = "/loading.png"; }
    ];
  };
}
