{ config, lib, pkgs, ... }:

with lib;

{
  options.mobile = {
    quirks.qualcomm.msm-fb-refresher = mkOption {
      type = types.bool;
      default = false;
      description = "Enables use of `msm-fb-refresher`.";
    };
  };
}
