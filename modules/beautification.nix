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
          description = ''
            When enabled, fbcon consoles are disabled.
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
  ];
}
