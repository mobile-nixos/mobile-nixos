{ config, lib, pkgs, ... }:

{
  mobile.device.name = "asus-x018d";
  mobile.device.identity = {
    name = "Asus Zenfone Max Plus (M1)";
    # AKA: ZB570TL, E262L
    manufacturer = "Asus";
  };

  mobile.hardware = {
    soc = "mediatek-mt6755";
    ram = 1024 * 2;
    screen = {
      width = 1080; height = 2160;
    };
  };

  mobile.boot.stage-1 = {
    kernel.package = pkgs.callPackage ./kernel { };
  };

  mobile.system.android.device_name = "ww_x018";
  mobile.system.android = {
    bootimg.flash = {
      offset_base = "0x40078000";
      offset_kernel = "0x00008000";
      offset_ramdisk = "0x04f88000";
      offset_second = "0x00f00000";
      offset_tags = "0x0bc08000";
      pagesize = "2048";
    };
  };

  # 16MiB boot partition.
  mobile.boot.stage-1.compression = lib.mkDefault "xz";

  boot.kernelParams = [
    "bootopt=64S3,32N2,64N2"
    "androidboot.selinux=permissive"
    "buildvariant=userdebug"
  ];

  mobile.usb.mode = "android_usb";
  # Google
  mobile.usb.idVendor = "18D1";
  # "Nexus 4"
  mobile.usb.idProduct = "D001";

  mobile.system.type = "android";
}
