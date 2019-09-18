{ config, lib, pkgs, ... }:

with lib;
let
  cfg = config.mobile.system;

  # Mapping from system types to config types
  # A simplified view of <nixpkgs/lib/systems/examples.nix>
  config_types = {
    aarch64-linux = "aarch64-unknown-linux-gnu";
    armv7l-linux = "armv7l-unknown-linux-gnueabihf";
    x86_64-linux = "x86_64-unknown-linux-gnu";
  };

  # Derived from config_types
  target_types = lib.attrNames config_types;

  # Builds the expected "platform" set for cross-compilation from the given
  # system name.
  selectPlatform = system: {
    inherit system;
    platform = lib.systems.platforms.selectBySystem system;
    config = config_types.${system};
  };

  # The platform selected by the configuration
  selectedPlatform = selectPlatform cfg.system;
in
{
  options.mobile = {
    system.system = mkOption {
      type = types.enum target_types;
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
          result = selectedPlatform.system != builtins.currentSystem;
        in
        builtins.trace
        "Building with crossSystem?: ${selectedPlatform.system} != ${builtins.currentSystem} → ${if result then "true" else "false"}"
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
