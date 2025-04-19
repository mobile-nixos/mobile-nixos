{ lib, pkgs, ... }:

{

  ### nix-build --argstr device nothing-spacewar -A outputs.android-fastboot-images

  imports = [
    ../families/sm7325-mainline
  ];

  mobile.boot.stage-1.kernel = {
    modules = [
      "drm"
      "drm_kms_helper"
      "panel-visionox-rm692e5"
      "msm"
      "spi-geni-qcom"
      "fts_tp"
      "fsa4480"
    ];
  };

  mobile.device.name = "nothing-spacewar";
  mobile.device.identity = {
    name = "Phone (1)";
    manufacturer = "Nothing";
  };

  # Willing to support if this reaches the quality to do so.
  mobile.device.supportLevel = "best-effort";

  mobile.hardware = {
    ram = 1024 * 8;
    screen = {
      width = 1080; height = 2400;
    };
  };

  mobile.device.firmware = pkgs.callPackage ./firmware {};

  mobile.system.android.device_name = "NothingPhone";

  boot.postBootCommands = ''
    echo "Hello from Mobile NixOS!" > /dev/tty0
  '';

  boot.kernelParams = lib.mkAfter [
    "console=ttyMSM0,115200n8"
    "console=tty0"
    "earlycon"
    "loglevel=7"
  ];
  boot.consoleLogLevel = 7;
}
