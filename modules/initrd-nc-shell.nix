{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.mobile.boot.stage-1.nc-shell;
in
{
  options.mobile.boot.stage-1.nc-shell = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        This is the "everything is going wrong" way to debug.
      '';
    };
  };

  config.mobile.boot.stage-1 = lib.mkIf cfg.enable {
    init = ''
      # THIS IS HIGHLY INSECURE
      nc -lk -p 2323 -e ${shell} &
    '';
  };
}
