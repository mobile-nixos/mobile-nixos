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
    stage-1 = {
      fb_modes = ./fb.modes;
      inherit (msm-fb-refresher.stage-1) initFramebuffer;
      packages = with pkgs; [
        strace
      ]
      # TODO : implement quirks
      ++ msm-fb-refresher.stage-1.packages
      ;
    };
  };
  mobile.hardware = {
    # This could also be pre-built option types?
    soc = "qualcomm-msm8939";
	screen = { width = 1080; height = 1920; };
  };
  mobile.system.type = "android-bootimg";
  mobile.boot.stage-1.initFramebuffer = ''
    echo 10 > /sys/class/leds/lcd-backlight/brightness
  '';
}
