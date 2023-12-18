{ config, lib, pkgs, ... }:

# This module provides the `recovery` build output.
# It is the same configuration, with minor customizations.

let
  inherit (lib)
    mkOption
  ;
in
{
  options = {
    mobile = {
      outputs = {
        recovery = mkOption {
          internal = true;
          description = lib.mdDoc ''
            The configuration, re-evaluated with assumptions for recovery use.
          '';
        };
      };
    };
  };

  config = {
      mobile.outputs.recovery = (config.lib.mobile-nixos.composeConfig {
      config = {
        mobile.system.android.bootimg.name = "recovery.img";
        mobile.boot.stage-1.bootConfig = {
          is_recovery = true;
        };
      };
    }).config;
  };
}
