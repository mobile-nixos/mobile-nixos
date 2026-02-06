{ config, lib, pkgs, ... }:

{
  imports = [
    ../families/sdm845-mainline
  ];

  mobile.system.android.kernelParams = [
    "console=ttyMSM0,115200"
    "loglevel=8"
  ];

  mobile.device.name = "shift-axolotl";
  mobile.device.identity = {
    name = "SHIFT6mq";
    manufacturer = "SHIFT";
  };
  mobile.device.supportLevel = "supported";

  mobile.hardware = {
    ram = 1024 * 8;
    screen = {
      width = 1080; height = 2160;
    };
  };

  # Touchscreen and device-specific modules in initrd
  mobile.boot.stage-1.kernel.modules = [
    "i2c_qcom_geni"
  ];
  mobile.device.firmware = pkgs.callPackage ./firmware {};

  mobile.system.android.device_name = "SHIFT6mq";
}
