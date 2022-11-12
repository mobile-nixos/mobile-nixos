{ config, lib, pkgs, ... }:

{
  mobile.device.name = "lenovo-krane";
  mobile.device.identity = {
    name = "Chromebook Duet";
    manufacturer = "Lenovo";
  };
  mobile.device.supportLevel = "supported";

  mobile.hardware = {
    soc = "mediatek-mt8183";
    ram = 1024 * 4;
    screen = {
      # Panel is portrait CW compared to keyboard attachment.
      width = 1200; height = 1920;
    };
  };

  mobile.boot.stage-1 = {
    kernel.package = pkgs.callPackage ./kernel {};
  };

  mobile.system.depthcharge.kpart = {
    dtbs = "${config.mobile.boot.stage-1.kernel.package}/dtbs/mediatek";
  };

  mobile.system.type = "depthcharge";
}
