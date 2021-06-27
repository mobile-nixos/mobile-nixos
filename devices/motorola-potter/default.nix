{ config, lib, pkgs, ... }:

{
  mobile.device.name = "motorola-potter";
  mobile.device.identity = {
    name = "Moto G5 Plus";
    manufacturer = "Motorola";
  };

  mobile.hardware = {
    soc = "qualcomm-msm8953";
    ram = 1024 * 2;
    screen = {
      width = 1080; height = 1920;
    };
  };

  mobile.boot.stage-1 = {
    kernel.package = pkgs.callPackage ./kernel { };
  };

  mobile.device.firmware = pkgs.callPackage ./firmware {};

  mobile.system.android.device_name = "potter";
  mobile.system.android.bootimg = {
    flash = {
      offset_base = "0x80000000";
      offset_kernel = "0x00008000";
      offset_ramdisk = "0x01000000";
      offset_second = "0x00f00000";
      offset_tags = "0x00000100";
      pagesize = "2048";
    };
  };

  # The boot partition on this phone is 16MB, so use `xz` compression
  # as smaller than gzip

  mobile.boot.stage-1.compression = lib.mkDefault "xz";

  mobile.usb.mode = "android_usb";
  # Google
  mobile.usb.idVendor = "18D1";
  # "Nexus 4"
  mobile.usb.idProduct = "D001";

  mobile.system.type = "android";

  mobile.quirks.qualcomm = {
    wcnss-wlan.enable = true;
  };
}
