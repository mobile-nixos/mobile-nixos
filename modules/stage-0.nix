{ config, lib, modules, baseModules, ... }:

# This module provides the `stage-0` build output.
# It is the same configuration, with minor customizations.

let 
  inherit (lib) mkOption types;
  inherit (config.mobile.quirks) supportsStage-0;
in
{
  options = {
    mobile.quirks.supportsStage-0 = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Set to false when a device cannot use `kexec` to kexec into a system.
      '';
    };
  };

  config = {
    system.build.stage-0 = (import ../lib/eval-config.nix {
      inherit baseModules;
      modules = modules ++ [{
        mobile.boot.stage-1.stage = if supportsStage-0 then 0 else 1;
      }];
    }).config;
  };
}
