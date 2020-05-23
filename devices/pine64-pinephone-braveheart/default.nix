{ config, lib, pkgs, ... }:

{
  mobile.device.name = "pine64-pinephone-braveheart";
  mobile.device.info = rec {
    name = "PinePhone “BraveHeart”";
    manufacturer = "Pine64";

    # Serial console on ttyS0, using the serial headphone adapter.
    kernel_cmdline = lib.concatStringsSep " " [
      "console=ttyS0,115200"
      "vt.global_cursor_default=0"
      "earlycon=uart,mmio32,0x01c28000"
      "panic=10"
      "consoleblank=0"
    ];
    # TODO : make kernel part of options.
    kernel = pkgs.callPackage ./kernel { kernelPatches = pkgs.defaultKernelPatches; };
  };

  mobile.hardware = {
    soc = "allwinner-a64";
    ram = 1024 * 2;
    screen = {
      width = 720; height = 1440;
    };
  };

  mobile.system.type = "u-boot";
  mobile.quirks.u-boot.package = pkgs.callPackage ./u-boot {};
  mobile.quirks.u-boot.additionalCommands = ''
    # Yellow LED.
    gpio set 115   # R
    gpio set 114   # G
    gpio clear 116 # B
  '';
}
