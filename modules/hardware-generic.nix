{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.mobile.hardware.socs;
in
{
  options.mobile = {
    hardware.socs.generic-x86_64.enable = mkOption {
      type = types.bool;
      default = false;
      description = "Enable when system is a generic x86_64";
    };
  };

  config = {
  };
}
