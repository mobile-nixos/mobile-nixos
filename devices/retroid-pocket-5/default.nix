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

  mobile.device.name = "retroid-pocket-5";
  mobile.device.identity = {
    name = "Retroid Pocket 5";
    manufacturer = "Retroid";
  };
  mobile.device.supportLevel = "best-effort";

  mobile.hardware = {
    ram = 1024 * 8;
    screen = {
      width = 1080;
      height = 2280;
    };
  };
  
  
  

  mobile.device.firmware = pkgs.callPackage ./firmware { };

  mobile.system.android.device_name = "Retroidp Pocket 5";
}
