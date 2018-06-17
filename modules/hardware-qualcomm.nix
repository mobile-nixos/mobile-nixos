{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.mobile.hardware.socs;
in
{
  options.mobile = {
    hardware.socs.qualcomm-msm8939.enable = mkOption {
      type = types.bool;
      default = false;
      description = "enable when SOC is msm8939";
    };
  };

  config = {
    # TODO : more generic than msm8939.enable.
    mobile.quirks.qualcomm.msm-fb-refresher.enable = cfg.qualcomm-msm8939.enable;
  };
}
