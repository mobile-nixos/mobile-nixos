{ config, lib, pkgs, ... }:

with lib;

{
  options.mobile.device = {
    name = mkOption {
      type = types.str;
      description = "The device's codename. Must match the device folder.";
    };

    info.kernel = mkOption {
      # FIXME: drop this option
      # This is only kept *currently* for the commit to still build.
      # This will be dealt with in the coming commits.
      internal = true;
    };

    identity = {
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
