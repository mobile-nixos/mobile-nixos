{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.mobile.boot.stage-1.telnet;
in
{
  options.mobile.boot.stage-1.telnet = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Enables telnet. This is insecure.
      '';
    };
  };

  config.mobile.boot.stage-1 = lib.mkIf cfg.enable {
    init = ''
      TELNET_PORT=23
      telnetd -p ''${TELNET_PORT} -l ${shell} &
    '';
  };
}
