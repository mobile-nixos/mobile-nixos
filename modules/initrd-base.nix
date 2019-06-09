{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.mobile.boot.stage-1;
in
{
  options.mobile.boot.stage-1.hard-reboot = {
    enable = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Adds hard-reboot/hard-shutdown script.
      '';
    };
  };

  config.mobile.boot.stage-1 = {
    extraUtils = with pkgs; lib.mkIf cfg.hard-reboot.enable [
      hard-reboot 
      hard-shutdown
    ];
  };
}
