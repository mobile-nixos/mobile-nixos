{ config, lib, pkgs, ... }:

with lib;
with import ./initrd-order.nix;

let
  cfg = config.mobile.boot.stage-1;
in
{
  options.mobile.boot.stage-1.hard-reboot = {
    enable = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Adds hard-reboot script.
      '';
    };
  };

  options.mobile.boot.stage-1.redirect-log = {
    enable = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Redirects init log to /init.log file.
      '';
    };
  };

  config.mobile.boot.stage-1 = {
    init = lib.mkIf cfg.redirect-log.enable (lib.mkOrder BEFORE_DEVICE_INIT ''
      exec >/init.log 2>&1
    '');
    extraUtils = with pkgs; lib.mkIf cfg.hard-reboot.enable [
      hard-reboot 
    ];
  };
}
