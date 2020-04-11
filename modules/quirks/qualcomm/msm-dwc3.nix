{ config, lib, pkgs, ... }:

let
  cfg = config.mobile.quirks.qualcomm;
  inherit (lib) mkIf mkOption types;
in
{
  options.mobile = {
    quirks.qualcomm.dwc3-otg_switch.enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Enable this on a device which requires otg_switch to be
        configured for OTG to work.
      '';
    };
  };

  config = mkIf (cfg.dwc3-otg_switch.enable) {
    mobile.boot.stage-1.tasks = [ ./msm-dwc3-otg_switch-task.rb ];
    systemd.services.dwc3-otg_switch = {
      description = "Setup the DWC3 controller in OTG mode";
      wantedBy = [ "multi-user.target" ];
      script = ''
        echo 1 > /sys/module/dwc3_msm/parameters/otg_switch
      '';
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
    };
  };
}
