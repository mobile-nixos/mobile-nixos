{ config, lib, ... }:

let
  inherit (lib)
    mkOption
    types
  ;
in
{
  options.mobile.hardware.ram = mkOption {
    type = types.int;
    description = ''
      Total RAM available (in MB, 1GB = 1024MB).

      This may be used to turn on or off features depending on the device's capabilities.
    '';
  };
}
