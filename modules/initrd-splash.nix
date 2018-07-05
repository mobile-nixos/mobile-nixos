{ config, lib, pkgs, ... }:

with lib;
with import ./initrd-order.nix;

let
  cfg = config.mobile.boot.stage-1.splash;
  mkSplash = at: name:
  {
    init = lib.mkOrder at ''
      show_splash ${name}
    '';
    contents = [
      {
        object = (builtins.path { path = ../artwork + "/${name}.png"; });
        symlink = "/${name}.png";
      }
    ];
  };
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
    rgb-debug = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Enables a special splash with RGB debug components.
      '';
    };
  };

  config.mobile.boot.stage-1 = lib.mkIf cfg.enable (mkMerge [
    {
      init = lib.mkOrder BEFORE_FRAMEBUFFER_INIT ''
        show_splash() {
          ply-image --clear=0x000000 /$1.png > /dev/null 2>&1
        }
      '';
      extraUtils = [
        { package = pkgs.ply-image; extraCommand = "cp -pv ${pkgs.glibc.out}/lib/libpthread.so.* $out/lib"; }
      ];
    }

    (mkSplash AFTER_FRAMEBUFFER_INIT "loading")
    (mkSplash (READY_INIT - 1) "splash")
    (mkIf cfg.rgb-debug (mkSplash (READY_INIT) "rgb-debug"))
  ]);
}
