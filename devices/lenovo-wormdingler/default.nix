{ config, lib, pkgs, ... }:

{
  imports = [
    ../families/mainline-chromeos-sc7180
  ];

  mobile.device.name = "lenovo-wormdingler";
  mobile.device.identity = {
    name = "Chromebook Duet 3 (11”)";
    manufacturer = "Lenovo";
  };
  mobile.device.supportLevel = "supported";

  mobile.hardware = {
    screen = {
      # Panel is portrait CW compared to keyboard attachment.
      width = 1200; height = 2000;
    };
  };

  # Ensure orientation match with keyboard.
  services.udev.extraHwdb = lib.mkBefore ''
    sensor:accel-display:modalias:platform:cros-ec-accel:*
      ACCEL_MOUNT_MATRIX=0, 1, 0; -1, 0, 0; 0, 0, -1
  '';
}
