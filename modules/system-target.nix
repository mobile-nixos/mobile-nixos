{ config, lib, pkgs, ... }:

with lib;
let
  cfg = config.mobile.system;
  inherit (config.nixpkgs) localSystem;

  # The platform selected by the configuration
  selectedPlatform = lib.systems.elaborate cfg.system;
in
{
  options.mobile = {
    system.system = mkOption {
      # Known supported target types for Mobile NixOS
      type = types.enum [
        "aarch64-linux"
        "armv7l-linux"
        "x86_64-linux"
      ];
      description = ''
        Defines the kind of target architecture system the device is.

        This will automagically setup cross-compilation where possible.
      '';
    };
  };

  config = {
    assertions = [
      {
        assertion = pkgs.targetPlatform.system == cfg.system;
        message = "pkgs.targetPlatform.system expected to be `${cfg.system}`, is `${pkgs.targetPlatform.system}`";
      }
    ];

    nixpkgs.crossSystem = lib.mkIf
      (
        let
          result = selectedPlatform.system != localSystem.system;
        in
        builtins.trace
        "Building with crossSystem?: ${selectedPlatform.system} != ${localSystem.system} → ${if result then "we are" else "we're not"}."
        result
      )
      (
        builtins.trace
        "    crossSystem: config: ${selectedPlatform.config}"
        selectedPlatform
      )
    ;
  };
}
