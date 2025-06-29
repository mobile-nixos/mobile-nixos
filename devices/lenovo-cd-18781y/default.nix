{ config, lib, pkgs, ... }:

{
  imports = [
    ../families/msm8953-mainline
  ];

  mobile.device.name = "lenovo-cd-18781y";
  mobile.device.identity = {
    name = "ThinkSmart View";
    manufacturer = "Lenovo";
  };
  mobile.device.supportLevel = "supported";
  mobile.hardware = {
    screen = {
      # Panel is portrait CW compared to keyboard attachment.
      width = 800; height = 1280;
    };
  };
#
#   # Ensure orientation match with keyboard.
#   services.udev.extraHwdb = lib.mkBefore ''
#     sensor:modalias:platform:*
#       ACCEL_MOUNT_MATRIX=0, 1, 0; -1, 0, 0; 0, 0, -1
#   '';
}
