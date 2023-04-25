{ config, lib, pkgs, ... }:

{
  imports = [
    ./sound.nix
  ];

  mobile.device.name = "pine64-pinetab";
  mobile.device.identity = {
    name = "PineTab";
    manufacturer = "Pine64";
  };

  mobile.hardware = {
    soc = "allwinner-a64";
    ram = 1024 * 2;
    screen = {
      width = 800; height = 1280;
    };
  };

  mobile.boot.stage-1 = {
    kernel.package = pkgs.callPackage ./kernel { };
  };

  boot.kernelParams = [
    "earlycon=uart,mmio32,0x01c28000"
    "panic=10"
    "consoleblank=0"
  ];

  # Serial console on ttyS0, using the serial headphone adapter.
  mobile.boot.serialConsole = "ttyS0,115200";

  mobile.system.type = "u-boot";

  mobile.usb.mode = "gadgetfs";

  # Commonly re-used values, Nexus 4 (debug)
  # (These identifiers have well-known default udev rules.)
  mobile.usb.idVendor = "18d1";
  mobile.usb.idProduct = "d002";

  mobile.usb.gadgetfs.functions = {
    rndis = "rndis.usb0";
    mass_storage = "mass_storage.0";
    adb = "ffs.adb";
  };

  mobile.boot.stage-1.bootConfig = {
    # Used by target-disk-mode to share the internal drive
    storage.internal = "/dev/disk/by-path/platform-1c11000.mmc";
  };

  mobile.device.firmware = pkgs.callPackage ./firmware {};

  # Supports rebooting into generation kernel through kexec.
  mobile.quirks.supportsStage-0 = true;

  mobile.quirks.fdt-forward = {
    props = [
      ["/soc/mmc@1c10000/wifi@1" "local-mac-address"]
    ];
  };
}
