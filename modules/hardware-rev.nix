{ config, lib, pkgs, ... }:

let
  inherit (lib) mkOption types;
  cfg = config.mobile.hardware;
in
{
  options.mobile.hardware = {
    rev = mkOption {
      # This is used to specify hardware revision if any.
      type = types.str;
      description = ''
        Give the hardware revision for the device.
      '';
    };
  };
}
