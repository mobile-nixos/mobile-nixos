{ config, lib, ... }:

let
  inherit (lib)
    mkOption
    types
  ;
in
{
  options.mobile.hardware.screen = {
    width = mkOption {
      type = types.int;
      description = lib.mdDoc ''
        Width of the device's display.
      '';
    };
    height = mkOption {
      type = types.int;
      description = lib.mdDoc ''
        Height of the device's display.
      '';
    };
  };
}
