{ config, lib, pkgs, extendModules, ... }:

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
          description = ''
            The configuration, re-evaluated with assumptions for recovery use.
          '';
        };
      };
    };
  };

  config = {
    mobile.outputs.recovery = (extendModules {
      modules = [
        {
          mobile.system.android.bootimg.name = "recovery.img";
          mobile.boot.stage-1.bootConfig = {
            is_recovery = true;
          };
        }
      ];
    }).config;
  };
}
