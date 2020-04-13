{ config, lib, pkgs, ... }:

let
  cfg = config.mobile.quirks.qualcomm;
  inherit (lib) mkIf mkOption types;
in
{
  options.mobile = {
    quirks.qualcomm.wcnss-wlan.enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Enable this on a device which uses wcnss wlan.
      '';
    };
  };

  config = mkIf (cfg.wcnss-wlan.enable) {
    systemd.services.setup-wcnss = {
      description = "Setup the wireless interface";
      wantedBy = [ "multi-user.target" ];
      script = ''
        # This ends up failing, even when successful.
        echo 1 > /dev/wcnss_wlan || :
        # If the previous failed, this fails, and is a safe no-op.
        echo sta > /sys/module/wlan/parameters/fwpath
      '';
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
    };
  };
}
