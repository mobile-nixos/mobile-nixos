{ config, lib, pkgs, ... }:

with lib;

{
  options.mobile.hardware.screen = {
    width = mkOption {
      type = types.integer;
    };
    height = mkOption {
      type = types.integer;
    };
  };
}
