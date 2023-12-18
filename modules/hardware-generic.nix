{ config, lib, pkgs, ... }:

let
  inherit (lib) mkMerge mkOption types;
  cfg = config.mobile.hardware.socs;
in
{
  options.mobile.hardware.socs = {
    # Please don't use `generic-*` SoCs in specific devices.
    generic-x86_64.enable = mkOption {
      type = types.bool;
      default = false;
      description = lib.mdDoc "Enable when system is a generic x86_64";
      internal = true;
    };
    generic-aarch64.enable = mkOption {
      type = types.bool;
      default = false;
      description = lib.mdDoc "Enable when system is a generic AArch64";
      internal = true;
    };
    generic-armv7l.enable = mkOption {
      type = types.bool;
      default = false;
      description = lib.mdDoc "Enable when system is a generic armv7l";
      internal = true;
    };
  };

  config = {
    mobile.system.system = mkMerge [
      (lib.mkIf cfg.generic-x86_64.enable "x86_64-linux")
      (lib.mkIf cfg.generic-armv7l.enable "armv7l-linux")
      (lib.mkIf cfg.generic-aarch64.enable "aarch64-linux")
    ];
  };
}
