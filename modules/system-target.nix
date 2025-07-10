{ config, lib, pkgs, ... }:

let
  inherit (lib)
    mkDefault
    mkIf
    mkOption
    types
  ;
  inherit (lib.systems)
    elaborate
  ;
  inherit (config)
    nixpkgs
  ;
  inherit (config.nixpkgs)
    hostPlatform
    localSystem
  ;
  cfg = config.mobile.system;

  # Use JSON to escape values for printing
  e = builtins.toJSON;

  # When `nixpkgs` is built on a different platform than it will be running on.
  isCross = deviceHostPlatform.system != localSystem.system;

  # The host platform selected by the Mobile device configuration
  deviceHostPlatform = elaborate cfg.system;

  # Be mindful about using `config` values that depends on `nixpkgs.buildPlatform`!
  # This is used when setting `nixpkgs.buildPlatform`, so any values depending on `nixpkgs.buildPlatform`,
  # including `nixpkgs.buildPlatform` will cause an infinite recursion.
  traceCrossBuildPlatform =
    buildPlatform:
    builtins.trace ''
      Building for cross?: ${e deviceHostPlatform.system} != ${e localSystem.system} → ${if isCross then "we are" else "we're not"}.
                nixpkgs.buildPlatform.config → ${e /*nixpkgs.*/buildPlatform.config}
                nixpkgs.hostPlatform.config → ${e nixpkgs.hostPlatform.config}
    '' buildPlatform
  ;
in
{
  options.mobile = {
    system.system = mkOption {
      # Known supported target types.
      type = types.enum [
        "aarch64-linux"
        "armv7l-linux"
        "x86_64-linux"
      ];
      description = ''
        Defines the host platform architecture the device is.

        This will automagically setup cross-compilation where possible.
      '';
    };
  };

  config = {
    assertions = [
      {
        assertion = cfg.system == pkgs.stdenv.targetPlatform.system;
        message = ''
          pkgs.stdenv.targetPlatform.system expected to be ${e cfg.system}, is ${e pkgs.stdenv.targetPlatform.system}
              nixpkgs.buildPlatform → ${e config.nixpkgs.buildPlatform.system}
              nixpkgs.hostPlatform → ${e config.nixpkgs.hostPlatform.system}
        '';
      }
    ];

    nixpkgs.hostPlatform =
      mkDefault deviceHostPlatform
    ;
    nixpkgs.buildPlatform =
      mkIf isCross (
        # We are only using `traceCrossBuildPlatform` when doing cross-compilation.
        # Otherwise it's noise for native builds.
        mkDefault (traceCrossBuildPlatform (elaborate localSystem.system))
      )
    ;
  };
}
