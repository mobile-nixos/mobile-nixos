{ config, pkgs, ... }:

# This module provides the `recovery` build output.
# It is the same configuration, with minor customizations.

{
  system.build.recovery = (config.lib.mobile-nixos.composeConfig {
    config = {
      mobile.system.android.bootimg.name = "recovery.img";
      mobile.boot.stage-1.bootConfig = {
        is_recovery = true;
      };
    };
  }).config;
}
