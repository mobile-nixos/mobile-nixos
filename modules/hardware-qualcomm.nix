{ config, lib, pkgs, ... }:

with lib;

{
  options.mobile = {
    hardware.qualcomm.msm8939.enable = mkOption {
      type = types.bool;
      default = false;
      description = "enable when SOC is msm8939";
    };
  };

  config = {
    # TODO : more generic than msm8939.enable.
    mobile.quirks.qualcomm.msm-fb-refresher.enable = config.mobile.hardware.qualcomm.msm8939.enable;
  };
}
