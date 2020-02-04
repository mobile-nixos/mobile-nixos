{ config, lib, pkgs, ... }:

let
  inherit (lib) mkIf mkOption types;

  withSplash = config.mobile.boot.stage-1.splash.enable;
  cfg = config.mobile.boot.stage-1.fail;
in
{
  options.mobile = {
    boot.stage-1.fail = {
      reboot = mkOption {
        type = types.bool;
        default = true;
        description = ''
          Reboots the device after a delay on failure.
        '';
      };
      delay = mkOption {
        type = types.int;
        default = 10;
        description = ''
          Duration (in seconds) before a reboot on failure.
        '';
      };
    };
  };

  config = mkIf cfg.reboot {
    mobile.boot.stage-1.contents = mkIf withSplash [
      {
        object = (builtins.path { path = ../artwork/sad-phone.png; });
        symlink = "/sad-phone.png";
      }
    ];
  };
}
