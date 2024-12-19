{ config, lib, pkgs, ... }:

let
  inherit (lib) types;
in
{
  options = {
    # All of this should stay internal.
    mobile.HAL = {
      boot = {
        rebootModes = lib.mkOption {
          type = types.listOf types.str;
          internal = true;
          default = [];
          description = ''
            Identifiers known by the boot menu to provide reboot options
            that are hardware-dependent. E.g. reboot to bootloader.
          '';
        };
      };
    };
  };
}
