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

  mobile.device.name = "sony-akatsuki";
  mobile.device.identity = {
    name = "Xperia XZ3";
    manufacturer = "Sony";
  };
  mobile.device.supportLevel = "supported";

  mobile.hardware = {
    ram = 1024 * 4;
    screen = {
      width = 1440;
      height = 2880;
    };
  };

  mobile.device.firmware = pkgs.callPackage ./firmware { };

  mobile.system.android.device_name = "Xperia XZ3";
}
