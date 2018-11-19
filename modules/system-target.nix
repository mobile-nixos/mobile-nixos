{ config, lib, pkgs, ... }:

# FIXME : current implementation only works for native x86_64 built hosts.

with lib;
let
  cfg = config.mobile.system;

  target_types = {
    aarch64-linux = lib.systems.examples.aarch64-multiplatform;
    armv7a-linux = lib.systems.examples.armv7l-hf-multiplatform;
    x86_64-linux = { config = "x86_64-unknown-linux-gnu"; };
  };

  # Hmmm, this doesn't feel right, but it does work.
  host_platform = (import <nixpkgs> {}).buildPackages.hostPlatform;
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
        message = "pkgs.targetPlatform.system expected to be `${cfg.platform}`, is `${pkgs.targetPlatform.system}`";
      }
    ];

    nixpkgs.crossSystem = lib.mkIf
      ( target_types.${cfg.platform}.config != host_platform.config )
      (target_types.${cfg.platform} // { system = cfg.platform; }) # FIXME : WHY? I didn't need to add system before :/
    ;
  };
}
