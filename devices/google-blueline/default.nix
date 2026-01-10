{
  config,
  lib,
  pkgs,
  ...
}:

{
  imports = [
    ../families/sdm845-mainline
  ];

  mobile.device.name = "google-blueline";

  mobile.device.identity = {
    name = "Pixel 3";
    manufacturer = "Google";
  };

  mobile.device.supportLevel = "supported";

  mobile.hardware = {
    ram = 1024 * 4;
    screen = {
      width = 1080;
      height = 2160;
    };
  };

  mobile.device.firmware = pkgs.callPackage ./firmware { };

  mobile.system.android.device_name = "Pixel 3";
}
