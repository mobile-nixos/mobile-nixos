{ config, lib, pkgs, ... }:

with lib;

{
  options.mobile = {
    device.name = mkOption {
      type = types.str;
      description = "The device's codename. Must match the device folder.";
    };
    device.info = mkOption {
      #type = types.attrSet;
      description = "system type specific informations";
      # This probably should be `internal`.
    };
    device.identity = {
      name = mkOption {
        type = types.str;
        description = "The device's name as advertised by the manufacturer.";
      };
      manufacturer = mkOption {
        type = types.str;
        description = "The device's manufacturer name.";
      };
    };
  };
}
