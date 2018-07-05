{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.mobile.hardware.screen;
in
{
  options.mobile.hardware.screen = {
    width = mkOption {
      type = types.int;
    };
    height = mkOption {
      type = types.int;
    };
  };
}
