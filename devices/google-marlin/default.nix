{ config, lib, pkgs, ... }:

{
  mobile.device.name = "google-marlin";
  mobile.device.identity = {
    name = "Google Pixel XL";
    manufacturer = "Google";
  };

  mobile.device.info = {
    # TODO : make kernel part of options.
    kernel = pkgs.callPackage ./kernel { kernelPatches = pkgs.defaultKernelPatches; };
  };

  mobile.hardware = {
    soc = "qualcomm-msm8996";
    ram = 1024 * 4;
    screen = {
      width = 1440; height = 2880;
    };
  };

  mobile.system.android = {
    # This device has an A/B partition scheme
    ab_partitions = true;

    bootimg.flash = {
      offset_base = "0x80000000";
      offset_kernel = "0x00008000";
      offset_ramdisk = "0x01000000";
      offset_second = "0x00f00000";
      offset_tags = "0x00000100";
      pagesize = "4096";
    };
  };

  mobile.system.vendor.partition = "/dev/disk/by-partlabel/vendor_a";

  boot.kernelParams = [
    "console=ttyHSL0,115200,n8"
    "androidboot.console=ttyHSL0"
    "androidboot.hardware=marlin"
    "user_debug=31"
    "ehci-hcd.park=3"
    "lpm_levels.sleep_disabled=1"
    "cma=32M@0-0xffffffff"
    "loop.max_part=7"
    "buildvariant=eng"
    "firmware_class.path=/vendor/firmware"
  ];

  mobile.usb.mode = "android_usb";
  # Google
  mobile.usb.idVendor = "18D1";
  # "Pixel" rndis+adb
  mobile.usb.idProduct = "4EE4";

  mobile.system.type = "android";
}
