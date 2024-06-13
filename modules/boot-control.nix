{ config, lib, pkgs, ... }:

let
  inherit (lib)
    mkIf
    mkOption
    types
  ;
in
{
  options = {
    mobile.boot.boot-control = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Enables usage of boot-control to mark A/B boot as successful.
        '';
      };
    };
  };

  config = mkIf config.mobile.boot.boot-control.enable {
    systemd.services = {
      boot-control = {
        enable = true;
        wantedBy = [ "multi-user.target" ];
        description = "Mark boot as successful";
        path = [ pkgs.mobile-nixos.boot-control ];
        script = ''
          boot-control --mark-successful
        '';
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };
      };
    };
  };
}
