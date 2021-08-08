{ pkgs, lib, ... }:

{
  mobile.device.name = "samsung-a5y17lte";
  mobile.device.identity = {
    name = "Galaxy A5 (2017)";
    manufacturer = "Samsung";
  };

  mobile.hardware = {
    soc = "exynos-7880";
    ram = 1024 * 3;
    screen = {
      width = 1080; height = 1920;
    };
  };

  mobile.boot.stage-1 = {
    kernel.package = pkgs.callPackage ./kernel { };
  };

  mobile.device.firmware = pkgs.callPackage ./firmware {};

  mobile.system.android.device_name = "a5y17lte";
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

  boot.kernelParams = [
    # Extracted from an Android boot image
    # (Actually blank!)
  ];

  mobile.boot.stage-1.compression = lib.mkDefault "xz";

  mobile.system.type = "android";

  mobile.usb.mode = "android_usb";
  mobile.usb.idVendor = "04E8"; # Samsung
  mobile.usb.idProduct = "6860"; # Galaxy A

  # qcacld-2.0 works the same way!
  mobile.quirks.qualcomm.wcnss-wlan.enable = true;
  mobile.quirks.wifi.disableMacAddressRandomization = true;
}
