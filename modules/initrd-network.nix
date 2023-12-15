{ config, lib, ... }:

let
  inherit (lib)
    mkOption
    types
  ;
  cfg = config.mobile.boot.stage-1.networking;
in
{
  options.mobile.boot.stage-1.networking = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = lib.mdDoc ''
        Enables networking.
      '';
    };
    IP = mkOption {
      type = types.str;
      default = "172.16.42.1";
      description = lib.mdDoc ''
        IP address for the USB networking gadget.
      '';
    };
    hostIP = mkOption {
      type = types.str;
      default = "172.16.42.2";
      description = lib.mdDoc ''
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
