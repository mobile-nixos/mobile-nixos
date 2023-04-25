{ config, lib, pkgs, ... }:

{
  mobile.device.name = "google-marlin";
  mobile.device.identity = {
    name = "Google Pixel XL";
    manufacturer = "Google";
  };

  mobile.hardware = {
    soc = "qualcomm-msm8996";
    ram = 1024 * 4;
    screen = {
      width = 1440; height = 2880;
    };
  };

  mobile.boot.stage-1 = {
    kernel.package = pkgs.callPackage ./kernel { };
  };

  mobile.device.firmware = pkgs.callPackage ./firmware {};
  mobile.device.enableFirmware = false;

  mobile.system.android.device_name = "marlin";
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

  # For use with the "Nexus-style" UART cable, add the following kernel parameter.
  mobile.boot.serialConsole = "ttyHSL0,115200n8";

  mobile.usb.mode = "android_usb";
  # Google
  mobile.usb.idVendor = "18D1";
  # "Pixel" rndis+adb
  mobile.usb.idProduct = "4EE4";

  mobile.system.type = "android";

  mobile.quirks.qualcomm.wcnss-wlan.enable = true;
  mobile.quirks.wifi.disableMacAddressRandomization = true;
}
