{ config, lib, pkgs, ... }:

{
  mobile.device.name = "xiaomi-begonia";
  mobile.device.identity = {
    name = "Redmi Note 8 Pro";
    manufacturer = "Xiaomi";
  };

  mobile.hardware = {
    soc = "mediatek-mt6785";
    # 4GB for the specific revision supported.
    # When this will be actually used, this may be dropped to 3, and/or
    # document all ram types as a list and work with min/max of those.
    ram = 1024 * 6;
    screen = {
      width = 1080; height = 2340;
    };
  };

  mobile.boot.stage-1 = {
    kernel.package = pkgs.callPackage ./kernel { };
  };

  mobile.system.android = {
    # This device adds skip_initramfs to cmdline for normal boots
    boot_as_recovery = true;

    # Though this device has "boot_as_recovery", it still has a classic
    # recovery partition for recovery. Go figure.
    has_recovery_partition = true;

    bootimg.flash = {
      offset_base = "0x40078000";
      offset_kernel = "0x00008000";
      offset_ramdisk = "0x07c08000";
      offset_second = "0x00f00000";
      offset_tags = "0x0bc08000";
      pagesize = "2048";
    };
  };

  mobile.system.vendor.partition = "/dev/disk/by-partlabel/vendor";

  boot.kernelParams = [
    # From TWRP CFW
    "bootopt=64S3,32N2,64N2"
    "androidboot.selinux=permissive"
    #"buildvariant=eng"
  ];

  mobile.system.type = "android";

  mobile.usb.mode = "gadgetfs";
  # FIXME: attribute to sources.
  mobile.usb.idVendor  = "2717"; # Xiaomi Communications Co., Ltd.
  mobile.usb.idProduct = "FF80"; # Mi/Redmi series (RNDIS)

  mobile.usb.gadgetfs.functions = {
    adb = "ffs.adb";
  };
}
