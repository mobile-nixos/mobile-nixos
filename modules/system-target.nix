{ config, lib, pkgs, ... }:

let
  inherit (lib)
    mkOption
    types
  ;
  cfg = config.mobile.system;
  inherit (config.nixpkgs) localSystem;

  # The platform selected by the configuration
  selectedPlatform = lib.systems.elaborate cfg.system;

  isCross = selectedPlatform.system != localSystem.system;
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
        assertion = pkgs.stdenv.targetPlatform.system == cfg.system;
        message = "pkgs.stdenv.targetPlatform.system expected to be `${cfg.system}`, is `${pkgs.stdenv.targetPlatform.system}`";
      }
    ];

    nixpkgs.crossSystem = lib.mkIf isCross (
      builtins.trace ''
        Building with crossSystem?: ${selectedPlatform.system} != ${localSystem.system} → ${if isCross then "we are" else "we're not"}.
               crossSystem: config: ${selectedPlatform.config}''
      selectedPlatform
    );
  };
}
