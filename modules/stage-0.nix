{ config, lib, pkgs, modules, baseModules, ... }:

# This module provides the `stage-0` build output.
# It is the same configuration, with minor customizations.

let 
  inherit (lib) mkOption types;
  inherit (config.mobile.quirks) supportsStage-0;
  kernelVersionSupportsKexec = 
    if pkgs.targetPlatform.system == "aarch64-linux"
    then (lib.versionAtLeast (config.mobile.boot.stage-1.kernel.package.version) "4.8")
    else true
  ;
in
{
  options = {
    mobile.quirks.supportsStage-0 = mkOption {
      type = types.bool;
      default = kernelVersionSupportsKexec;
      defaultText = "(Varies per platform; aarch64 depends on kernel version.)";
      description = ''
        Set to false when a device cannot use `kexec` to kexec into a system.

        A default value will be selected according to the platform and
        `mobile.boot` kernel selected.
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
