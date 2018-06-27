{ config, lib, pkgs, ... }:

# FIXME : current implementation only works for native x86_64 built hosts.

with lib;
let
  cfg = config.mobile.system;

  target_types = {
    aarch64-linux = lib.systems.examples.aarch64-multiplatform;
    x86_64-linux = null; # TODO : cross-compile from ARM and others!
  };
in
{
  options.mobile = {
    system.platform = mkOption {
      type = types.enum (lib.attrNames target_types);
      description = ''
        Defines the kind of target architecture system the device is.

        This will automagically setup cross-compilation where possible.
      '';
    };
  };

  config = {
    assertions = [
      {
        assertion = pkgs.targetPlatform.system == cfg.platform;
        message = "pkgs.targetPlatform.system expected to be `aarch64-linux`, is `${pkgs.targetPlatform.system}`";
      }
    ];

    nixpkgs.crossSystem = target_types.${cfg.platform};
  };
}
