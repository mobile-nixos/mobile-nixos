{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.mobile.hardware.soc;
in
{
  options.mobile.hardware = {
    soc = mkOption {
      # This is used to enable a specific SOC on a device, while giving it a name.
      type = types.string;
      description = ''
        Give the SOC name for the device.
      '';
    };
  };

  config = {
    assertions = [
      { assertion = mobile.hardware.socs ? cfg; message = "Cannot enable SOC ${cfg}; it is unknown."; }
    ];
    mobile.hardware.socs."${cfg}".enable = true;
  };
}
