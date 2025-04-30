{ lib, pkgs, ... }:

{

  ### nix-build --argstr device nothing-spacewar -A outputs.android-fastboot-images

  imports = [
    ../families/sm7325-mainline
  ];

  mobile.boot.stage-1.kernel = {
    modules = [
      "fsa4480"
      "msm"
      "panel-visionox-rm692e5"
      "spi-geni-qcom"
      "fts_tp"
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

  boot.kernelParams = lib.mkAfter [
    "root=/dev/disk/by-label/userdata"
    "rootwait"
    "rw"
  ];
  boot.consoleLogLevel = 7;
}
