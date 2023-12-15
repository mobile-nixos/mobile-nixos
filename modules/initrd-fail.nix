{ config, lib, pkgs, ... }:

let
  inherit (lib) mkOption types;
in
{
  options.mobile = {
    boot.stage-1.fail = {
      reboot = mkOption {
        type = types.bool;
        default = true;
        description = lib.mdDoc ''
          Reboots the device after a delay on failure.
        '';
      };
      delay = mkOption {
        type = types.int;
        default = 10;
        description = lib.mdDoc ''
          Duration (in seconds) before a reboot on failure.
        '';
      };
    };
  };
}
