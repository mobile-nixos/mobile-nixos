{
  pkgs,
  lib,
  ...
}:
let
  config = (lib.importJSON ../postmarketOS-devices.json).asus-z00t;
in
config // {
  name = config.pm_name;
  stage-1 = {
    fb_modes = ./fb.modes;
    packages = with pkgs; [
      strace
      msm-fb-refresher
    ];
    initFramebuffer = ''
      msm-fb-refresher --loop &
      echo 10 > /sys/class/leds/lcd-backlight/brightness
    '';
  };
}
