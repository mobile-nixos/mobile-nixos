{ config, lib, pkgs, ... }:

{
  mobile.device.name = "pine64-pinephone-braveheart";
  mobile.device.identity = {
    name = "PinePhone “BraveHeart”";
    manufacturer = "Pine64";
  };

  mobile.hardware = {
    soc = "allwinner-a64";
    ram = 1024 * 2;
    screen = {
      width = 720; height = 1440;
    };
  };

  mobile.boot.stage-1 = {
    kernel.package = pkgs.callPackage ./kernel { kernelPatches = pkgs.defaultKernelPatches; };
  };

  boot.kernelParams = [
    # Serial console on ttyS0, using the serial headphone adapter.
    "console=ttyS0,115200"
    "vt.global_cursor_default=0"
    "earlycon=uart,mmio32,0x01c28000"
    "panic=10"
    "consoleblank=0"
  ];

  mobile.system.type = "u-boot";

  mobile.device.firmware = pkgs.callPackage ./firmware {};

  mobile.quirks.u-boot.package = pkgs.callPackage ./u-boot {};
  mobile.quirks.u-boot.additionalCommands = ''
    # Yellow LED.
    gpio set 115   # R
    gpio set 114   # G
    gpio clear 116 # B

    # Properly shut off EG25 by pulling up PWRKEY.
    gpio set 35
    sleep 1
    gpio clear 35
  '';
}
