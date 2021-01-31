{ pkgs, ... }:

{
  mobile.device.name = "motorola-surfna";
  mobile.device.identity = {
    name = "Moto E6";
    manufacturer = "Motorola";
  };

  mobile.hardware = {
    soc = "qualcomm-msm8940";
    ram = 1024 * 2;
    screen = {
      width = 720; height = 1440;
    };
  };

  mobile.boot.stage-1 = {
    kernel.package = pkgs.callPackage ./kernel { };
  };

  mobile.system.android = {
    # This device adds skip_initramfs to cmdline for normal boots
    boot_as_recovery = true;

    # Though this device has "boot_as_recovery", it still has a classic
    # recovery partition for recovery.
    has_recovery_partition = true;

    bootimg.flash = {
      offset_base = "0x80000000";
      offset_kernel = "0x00008000";
      offset_ramdisk = "0x01000000";
      offset_second = "0x00f00000";
      offset_tags = "0x00000100";
      pagesize = "2048";
    };
  };

  mobile.system.vendor.partition = "/dev/disk/by-partlabel/vendor";

  boot.kernelParams = [
  ];

  mobile.system.type = "android";

  mobile.usb.mode = "gadgetfs";
  mobile.usb.idVendor  = "22B8"; # Motorola
  mobile.usb.idProduct = "2E81"; # "Moto G"

  mobile.usb.gadgetfs.functions = {
    rndis = "rndis_bam.rndis";
    adb = "ffs.adb";
  };
}
