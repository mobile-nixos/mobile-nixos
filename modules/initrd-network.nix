{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.mobile.boot.stage-1.networking;
  IP = cfg.IP;
  hostIP = cfg.hostIP;
in
{
  options.mobile.boot.stage-1.networking = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Enables networking.
      '';
    };
    IP = mkOption {
      type = types.str;
      default = "172.16.42.1";
      description = ''
        IP address for the USB networking gadget.
      '';
    };
    hostIP = mkOption {
      type = types.str;
      default = "172.16.42.2";
      description = ''
        IP address for the USB networking gadget.
      '';
    };
  };

  config.mobile.boot.stage-1 = lib.mkIf cfg.enable {
    tasks = [
      ./stage-1/tasks/dhcpd-task.rb
    ];
    bootConfig = {
      boot.networking = cfg;
    };
  };
}
