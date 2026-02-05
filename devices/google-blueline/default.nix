{ config, lib, pkgs, ... }:

{
  imports = [
    ../families/sdm845-mainline
  ];

  mobile.device.name = "google-blueline";

  # Kernel command line parameters for the boot image
  # Note: Use mobile.system.android.kernelParams for Android devices to avoid
  # inheriting unwanted NixOS system defaults (like loglevel=4, lsm=landlock,yama,bpf)
  mobile.system.android.kernelParams = [
    "console=ttyMSM0,115200"
    "loglevel=8"
  ];

  mobile.device.identity = {
    name = "Pixel 3";
    manufacturer = "Google";
  };

  mobile.device.supportLevel = "supported";

  mobile.hardware = {
    ram = 1024 * 4;
    screen = {
      width = 1080; height = 2160;
    };
  };

  mobile.device.firmware = pkgs.callPackage ./firmware {};

  mobile.system.android.device_name = "Pixel 3";
}
