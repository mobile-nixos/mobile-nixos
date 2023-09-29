{ config, lib, pkgs, ... }:

{
  imports = [
    ../families/mainline-chromeos-sc7180
  ];

  mobile.device.name = "acer-lazor";
  mobile.device.identity = {
    name = "Chromebook Spin 513";
    manufacturer = "Acer";
  };
  mobile.device.supportLevel = "supported";

  mobile.hardware = {
    screen = {
      width = 1920; height = 1080;
    };
  };
}
