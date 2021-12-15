{ config, lib, pkgs, ... }:
{
  mobile.device.name = "pine64-pinephonepro";
  mobile.device.identity = {
    name = "Pinephone Pro";
    manufacturer = "Pine64";
  };

  boot.kernelParams = [
    # Serial console on ttyS2, using the dedicated cable.
    "console=ttyS2,115200"
    "earlycon=uart8250,mmio32,0xff1a0000"
    "earlyprintk"

    "quiet"
    "vt.global_cursor_default=0"
  ];

  mobile.boot.stage-1 = {
    kernel.package = pkgs.callPackage ./kernel { };
  };

  mobile.hardware = {
    soc = "rockchip-rk3399s";
    ram = 1024 * 4;
    screen = {
      width = 720; height = 1440;
    };
  };

  mobile.system.type = "u-boot";
  # By design we're not adding a U-Boot package.
  # We're starting to dogfood using Tow-Boot.

  mobile.device.firmware = pkgs.callPackage ./firmware {};
  mobile.boot.stage-1.firmware = [
    config.mobile.device.firmware
  ];

  mobile.usb.mode = "gadgetfs";

  # It seems Pine64 does not have an idVendor...
  mobile.usb.idVendor = "1209";  # http://pid.codes/1209/
  mobile.usb.idProduct = "0069"; # "common tasks, such as testing, generic USB-CDC devices, etc."

  # Mainline gadgetfs functions
  mobile.usb.gadgetfs.functions = {
    rndis = "rndis.usb0";
    mass_storage = "mass_storage.0";
    adb = "ffs.adb";
  };

  mobile.boot.stage-1.bootConfig = {
    # Used by target-disk-mode to share the internal drive
    storage.internal = "/dev/disk/by-path/platform-fe330000.mmc";
  };

  mobile.boot.stage-1.tasks = [ ./usb_role_switch_task.rb ];
}
