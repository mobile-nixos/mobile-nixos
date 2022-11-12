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

  boot.kernelParams = [
    # Serial console on ttyS0, using a suzyqable or equivalent.
    # TODO: option to enable serial console.
    #"console=ttyS0,115200n8"
    #"earlyprintk=ttyS0,115200n8"
  ];

  mobile.system.type = "depthcharge";

  mobile.device.firmware = pkgs.callPackage ./firmware {};
  mobile.boot.stage-1.firmware = [
    config.mobile.device.firmware
  ];
}
