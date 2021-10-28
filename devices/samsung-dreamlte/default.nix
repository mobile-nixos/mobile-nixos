{ config, lib, pkgs, ... }:

{
  mobile.device.name = "samsung-dreamlte";
  mobile.device.identity = {
    name = "Galaxy S8";
    manufacturer = "Samsung";
  };

  mobile.hardware = {
    soc = "exynos-8895";
    ram = 1024 * 4;
    screen = {
      width = 1440; height = 2960;
    };
  };

  mobile.boot.stage-1 = {
    kernel.package = pkgs.callPackage ./kernel { };
  };

  mobile.system.android.device_name = "dreamlte";
  mobile.system.android = {
    bootimg.flash = {
      offset_base = "0x10000000";
      offset_kernel = "0x00008000";
      offset_ramdisk = "0x01000000";
      offset_second = "0x00f00000";
      offset_tags = "0x00000100";
      pagesize = "2048";
    };
    flashingMethod = "odin";
    boot_partition_destination = "BOOT";
  };

  boot.kernelParams = [ ];

  mobile.boot.stage-1.compression = lib.mkDefault "xz";

  mobile.system.type = "android";

  mobile.usb.mode = "gadgetfs";
  mobile.usb.gadgetfs.functions = {
    rndis = "rndis.usb0";
  };
  mobile.usb.idVendor = "04E8"; # Samsung
  mobile.usb.idProduct = "6860"; # Galaxy A
}
