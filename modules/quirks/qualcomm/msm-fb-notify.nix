{ config, lib, pkgs, ... }:

let
  cfg = config.mobile.quirks.qualcomm;
  inherit (lib) mkIf mkOption types;
in
{
  options.mobile = {
    quirks.qualcomm.fb-notify.enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Enable this on a device which requires the framebuffer
        to be notified for some components to work right.

        The most likely thing this fixes is touch input.
      '';
    };
  };

  config = mkIf (cfg.fb-notify.enable) {
    mobile.boot.stage-1.tasks = [ ./msm-fb-notify-task.rb ];
  };
}
