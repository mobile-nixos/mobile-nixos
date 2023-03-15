{ config, lib, pkgs, ... }:

let
  inherit (lib)
    mkDefault
    mkIf
    mkMerge
    mkOption
    types
  ;
in
{
  options = {
    mobile = {
      beautification = {
        silentBoot = mkOption {
          type = types.bool;
          default = false;
          description = lib.mdDoc ''
            When enabled, fbcon consoles are disabled.
          '';
        };
        splash = mkOption {
          type = types.bool;
          default = false;
          description = lib.mdDoc ''
            When enabled, plymouth is configured with nice defaults.

            Note that this requires an update to the kernel command-line
            parameters, thus the boot image may need to be reflashed.
          '';
        };
      };
    };
  };

  config = mkMerge [
    (mkIf config.mobile.beautification.silentBoot {
      boot.kernelParams = lib.mkBefore [
        "fbcon=vc:2-6"
        "console=tty0"
      ];
    })
    (mkIf config.mobile.beautification.splash {
      boot.plymouth.enable = mkDefault true;
      boot.plymouth.theme = mkDefault "spinner";
    })
  ];
}
