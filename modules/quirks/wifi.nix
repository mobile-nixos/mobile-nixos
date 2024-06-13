{ config, lib, pkgs, ... }:

let
  inherit (lib) mkOption types mkIf;
  cfg = config.mobile.quirks;
in
{
  options.mobile.quirks.wifi = {
    disableMacAddressRandomization = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Disables MAC address randomization.

        This may be required by some hardware or drivers, or combination.
        When the feature is enabled (quirk disabled) it may cause the wifi
        interface to disappear when enabled, as long as Network Manager is
        active.
      '';
    };
  };

  config = mkIf cfg.wifi.disableMacAddressRandomization {
    environment.etc."NetworkManager/conf.d/30-mac-randomization.conf" = {
      source = pkgs.writeText "30-mac-randomization.conf" ''
        [device-mac-randomization]
        wifi.scan-rand-mac-address=no

        [connection-mac-randomization]
        ethernet.cloned-mac-address=preserve
        wifi.cloned-mac-address=preserve
      '';
      target = "NetworkManager/conf.d/30-mac-randomization.conf";
    };
  };
}
