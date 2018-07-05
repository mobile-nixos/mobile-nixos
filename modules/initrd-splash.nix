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

  config.mobile.boot.stage-1 = lib.mkIf cfg.enable (mkMerge [
    {
      init = lib.mkOrder AFTER_FRAMEBUFFER_INIT ''
        show_splash() {
          ply-image /$1.png > /dev/null 2>&1
        }

        show_splash loading
      '';
      extraUtils = [
        { package = pkgs.ply-image; extraCommand = "cp -pv ${pkgs.glibc.out}/lib/libpthread.so.* $out/lib"; }
      ];
      contents = [
        { object = ../artwork/loading.png; symlink = "/loading.png"; }
      ];
    }
    {
      init = lib.mkOrder READY_INIT ''
        show_splash splash
      '';
      contents = [
        { object = ../artwork/temp-splash.png; symlink = "/splash.png"; }
      ];
    }
  ]);
}
