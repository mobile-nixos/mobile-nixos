{ config, lib, pkgs, ... }:

with lib;

{
  options.mobile = {
    device.name = mkOption {
      type = types.str;
    };
    device.info = mkOption {
      #type = types.attrSet;
      description = "system type specific informations";
      # This probably should be `internal`.
    };
  };
}
