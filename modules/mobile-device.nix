{ config, lib, pkgs, ... }:

with lib;

{
  options.mobile.device = {
    name = mkOption {
      type = types.str;
      description = "The device's codename. Must match the device folder.";
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

    firmware = mkOption {
      type = types.package;
      description = ''
        Informal option that the end-user can use to get their device's firmware package

        The device configuration may provide this option so the user can simply
        use `hardware.firmware = [ config.mobile.device.firmware ];`.

        Note that not all devices provide a firmware bundle, in this case the
        user should not add the previous example to their configuration.

        This is not added automatically to the system firmwares as most device
        firmware bundles will be unredistributable.
      '';
    };
  };
}
