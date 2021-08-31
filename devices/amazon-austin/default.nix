{ lib, pkgs, ... }:

{
  mobile.device.name = "amazon-austin";
  mobile.device.identity = {
    name = "Fire 7 (7th generation) (2017)";
    manufacturer = "Amazon";
  };

  mobile.hardware = {
    soc = "mediatek-mt8127";
    ram = 1024 * 1;
    screen = {
      width = 600; height = 1024;
    };
  };

  mobile.boot.stage-1 = {
    kernel.package = pkgs.callPackage ./kernel { };
  };

  mobile.system.android.device_name = "austin";
  mobile.system.android = {
    bootimg.flash = {
      offset_base = "0x80000000";
      offset_kernel = "0x00008000";
      offset_ramdisk = "0x04000000";
      offset_second = "0x00f00000";
      offset_tags = "0x00000100";
      pagesize = "2048";
    };
  };

  # The bootloader strips `console=` arguments.
  # If you need to set any, customize CONFIG_CMDLINE in the kernel configuration.
  boot.kernelParams = [
  ];

  mobile.system.type = "android";

  mobile.usb.mode = "android_usb";

  # Google
  mobile.usb.idVendor = "18D1";
  # "Nexus 4"
  mobile.usb.idProduct = "D001";

  # The vendor kernel has loads of issues building with USER_NS.
  # For now disable it. Patching should be possible, but will take time.
  mobile.kernel.structuredConfig = [
    (helpers: with helpers; {
      USER_NS = lib.mkForce no;
      UIDGID_STRICT_TYPE_CHECKS = lib.mkForce no;
    })
  ];
}
