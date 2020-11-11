{ config, lib, pkgs, modules, baseModules, _mobile-nixos, ... }:

# This module provides the `stage-0` build output.
# It is the same configuration, with minor customizations.

let 
  inherit (lib) mkOption types;
  inherit (config.mobile.quirks) supportsStage-0;
  inherit (config.mobile.boot.stage-1) kernel;
in
{
  options = {
    mobile.quirks.supportsStage-0 = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Set to true when a device, and its kernel, can use kexec.

        This will enable booting into the generation's kernel.
      '';
    };
  };

  config = {
    system.build.stage-0 = (_mobile-nixos.evalConfig {
      inherit baseModules;
      modules = modules ++ [{
        mobile.boot.stage-1.stage = if supportsStage-0 then 0 else 1;
      }];
    }).config;
  };
}
