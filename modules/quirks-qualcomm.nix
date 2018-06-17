{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.mobile.quirks.qualcomm;
in
{
  options.mobile = {
    quirks.qualcomm.msm-fb-refresher.enable = mkOption {
      type = types.bool;
      default = false;
      description = "Enables use of `msm-fb-refresher`.";
    };
  };

  config.mobile.boot = mkIf cfg.msm-fb-refresher.enable {
    stage-1 = {
      extraUtils = with pkgs; [
        msm-fb-refresher
      ];
      initFramebuffer = ''
        msm-fb-refresher --loop &
      '';
    };
  };
}
