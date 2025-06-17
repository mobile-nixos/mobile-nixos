{ config, lib, pkgs, ... }:

let
  inherit (lib)
    mkIf
    mkMerge
    mkOption
    mkOptionDefault
    types
  ;
  cfg = config.mobile.hardware;

  defaultValue = "generic-${config.nixpkgs.localSystem.parsed.cpu.name}";
in
{
  options.mobile.hardware = {
    soc = mkOption {
      # This is used to enable a specific SOC on a device, while giving it a name.
      type = types.str;
      description = ''
        Give the SOC name for the device.
      '';
    };
  };

  config = mkMerge [
    # Ensure assertion is not added if Mobile NixOS is not used.
    (mkIf (cfg.soc != defaultValue) {
      assertions = [
        { assertion = cfg.socs ? ${cfg.soc}; message = "Cannot enable SOC ${cfg.soc}; it is unknown.";}
      ];
    })
    {
      mobile.hardware.socs."${cfg.soc}".enable = true;

      # When evaluating with the Mobile NixOS defaults disabled, we want
      # to use the a generic type so evaluation can continue.
      # Otherwise we want to error on an unset value if not set.
      mobile.hardware.soc = mkIf (!config.mobile.enable) (
        mkOptionDefault defaultValue
      );
    }
  ];
}
