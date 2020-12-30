{ modules, baseModules, ... }:

# This module provides the `recovery` build output.
# It is the same configuration, with minor customizations.

{
  system.build.recovery = (import ../lib/eval-config.nix {
    inherit baseModules;
    modules = modules ++ [{
      mobile.system.android.bootimg.name = "recovery.img";
      mobile.boot.stage-1.bootConfig = {
        is_recovery = true;
      };
    }];
  }).config;
}
