{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.mobile.boot.stage-1.splash;
  image = name: ../artwork + "/${name}.png";
  addSplash = name:
  {
    contents = [
      {
        object = (builtins.path { path = image name; });
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
      extraUtils = [
        { package = pkgs.ply-image; extraCommand = "cp -pv ${pkgs.glibc.out}/lib/libpthread.so.* $out/lib"; }
      ];
    }

    # This is as early as we can splash...
    (addSplash "splash.stage-0")
    # Though there's still some setting-up in stage-1,
    # This is where "init is ready".
    (addSplash "splash.stage-1")
    # FIXME: Add a task / example (debug) image using this.
    #(mkIf cfg.rgb-debug (addSplash "rgb-debug"))
  ]);

  # This happens in stage-2. This is why we're not using `addSplash`.
  # This is the earliest in stage-2 we can show, for vt-less devices, that
  # stage-2 is really happening.
  config.boot.postBootCommands = ''
    ${pkgs.ply-image}/bin/ply-image --clear=0x000000 ${image "splash.stage-2"} > /dev/null 2>&1
  '';
}
