{ config, lib, pkgs, ... }:

{
  imports = [
    ../families/sdm845-mainline
  ];

  mobile.device.name = "google-blueline";
  mobile.device.identity = {
    name = "Pixel 3";
    manufacturer = "Google";
  };

  mobile.hardware = {
    ram = 1024 * 4;
    screen = {
      width = 1080; height = 2160;
    };
  };

  # Uses a custom kernel for now; not yet in proper sdm845-mainline.
  mobile.boot.stage-1.kernel.package = lib.mkForce (pkgs.callPackage ./kernel { });

  mobile.device.firmware = pkgs.callPackage ./firmware {};

  mobile.system.android = {
    device_name = "blueline";
    # Not boot as recovery. (Will not provide skip_initramfs on normal boots.)
    boot_as_recovery = false;
  };

  boot.kernelParams = lib.mkAfter [
    # If this is not present, the system will fail to boot reliably.
    # TODO: investigate if this is true when UART is not enabled in fastboot.
    "console=ttyMSM0,115200n8"
  ];
}
