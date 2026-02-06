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

  mobile.device.name = "xiaomi-beryllium";
  mobile.device.identity = {
    name = "Poco F1";
    manufacturer = "Xiaomi";
  };
  mobile.device.supportLevel = "supported";

  mobile.hardware = {
    ram = 1024 * 6;
    screen = {
      width = 1080;
      height = 2246;
    };
  };

  mobile.device.firmware = pkgs.callPackage ./firmware { };

  mobile.system.android.device_name = "Poco F1";
}
