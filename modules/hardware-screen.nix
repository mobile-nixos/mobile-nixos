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
      description = ''
        Width of the device's display.
      '';
    };
    height = mkOption {
      type = types.int;
      description = ''
        Height of the device's display.
      '';
    };
  };
}
