{ lib, pkgs, ... }:

{
  imports = [
    ./wifi.nix
  ];

  mobile.device.name = "amazon-karnak";
  mobile.device.identity = {
    name = "Fire HD 8 (8th generation) (2018)";
    manufacturer = "Amazon";
  };

  mobile.hardware = {
    soc = "mediatek-mt8163";
    ram = 1536;
    screen = {
      width = 800; height = 1280;
    };
  };

  mobile.boot.stage-1 = {
    kernel.package = pkgs.callPackage ./kernel { };
    compression = lib.mkDefault "xz";
  };

  mobile.device.firmware = pkgs.callPackage ./firmware { };

  mobile.system.android = {
    device_name = "karnak";
    bootimg.flash = {
      offset_base = "0x40080000";
      offset_kernel = "0x00000000";
      offset_ramdisk = "0x03400000";
      offset_second = "0x00e80000";
      offset_tags = "0x07f80000";
      pagesize = "2048";
    };
  };

  boot.kernelParams = [
    # Extracted from an Android boot image
    "console=ttyMT0,921600n1"
    "bootopt=64S3,32N2,64N2"
    "buildvariant=user"
  ];

  mobile.boot.stage-1.usb.enable = false;

  mobile.system.type = "android";

  mobile.usb.mode = "android_usb";

  # Google
  mobile.usb.idVendor = "18D1";
  # "Nexus 4"
  mobile.usb.idProduct = "D001";
}
