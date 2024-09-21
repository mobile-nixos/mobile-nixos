{ config, lib, pkgs, ... }:

{
  imports = [
    ../families/mainline-chromeos-mt8183
  ];

  mobile.device.name = "lenovo-kodama";
  mobile.device.identity = {
    name = "Chromebook 10e";
    manufacturer = "Lenovo";
  };
  mobile.device.supportLevel = "supported";
  mobile.hardware = {
    screen = {
      # Panel is portrait CW compared to keyboard attachment.
      width = 1200; height = 1920;
    };
  };

  # Ensure orientation match with keyboard.
  services.udev.extraHwdb = lib.mkBefore ''
    sensor:modalias:platform:*
      ACCEL_MOUNT_MATRIX=0, 1, 0; -1, 0, 0; 0, 0, -1 # Last I checked, this is wrong for this device
  '';
}
