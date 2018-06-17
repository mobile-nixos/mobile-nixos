{ config, lib, pkgs, ... }:
let
  msm-fb-refresher = (import ../../quirks/qualcomm/msm-fb-refresher.nix) { inherit pkgs lib; };
in
{
  mobile.device.name = "asus-z00t";
  mobile.device.info = (lib.importJSON ../postmarketOS-devices.json).asus-z00t // {
    # TODO : make kernel part of options.
    kernel = pkgs.callPackage ./kernel { kernelPatches = pkgs.defaultKernelPatches; };
    # TODO : make stage-1 part of options.
  };
  mobile.hardware = {
    # This could also be pre-built option types?
    soc = "qualcomm-msm8939";
    screen = {
      width = 1080; height = 1920;
      fb_modes = ./fb.modes;
    };
  };
  mobile.system.type = "android-bootimg";
  mobile.boot.stage-1 = {
    extraUtils = with pkgs; [
      strace
    ];
    initFramebuffer = ''
      echo 10 > /sys/class/leds/lcd-backlight/brightness
    '';
  };
}
