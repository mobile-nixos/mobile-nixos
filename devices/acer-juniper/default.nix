{ config, lib, pkgs, ... }:

{
  imports = [
    ../families/mainline-chromeos-mt8183
  ];

  mobile.device.name = "acer-juniper";
  mobile.device.identity = {
    name = "Chromebook 311";
    manufacturer = "Acer";
  };
  mobile.device.supportLevel = "supported";
  mobile.hardware = {
    screen = {
      width = 1366; height = 768;
    };
  };
}
