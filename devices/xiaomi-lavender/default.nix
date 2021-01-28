{ config, lib, pkgs, ... }:

{
  mobile.device.name = "xiaomi-lavender";
  mobile.device.identity = {
    name = "Redmi Note 7";
    manufacturer = "Xiaomi";
  };

  mobile.hardware = {
    soc = "qualcomm-sdm660";
    # 4GB for the specific revision supported.
    # When this will be actually used, this may be dropped to 3, and/or
    # document all ram types as a list and work with min/max of those.
    ram = 1024 * 4;
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
      offset_base = "0x00000000";
      offset_kernel = "0x00008000";
      offset_ramdisk = "0x01000000";
      offset_second = "0x00f00000";
      offset_tags = "0x00000100";
      pagesize = "4096";
    };
  };

  mobile.system.vendor.partition = "/dev/disk/by-partlabel/vendor";

  boot.kernelParams = [
    "earlycon=msm_serial_dm,0xc170000"
    "androidboot.hardware=qcom"
    "user_debug=31"
    "msm_rtb.filter=0x37"
    "ehci-hcd.park=3"
    "lpm_levels.sleep_disabled=1"
    "sched_enable_hmp=1"
    "sched_enable_power_aware=1"
    "service_locator.enable=1"
    "swiotlb=1"
    "firmware_class.path=/vendor/firmware_mnt/image"
    "loop.max_part=7"
    "androidboot.selinux=permissive"
    "buildvariant=userdebug"
  ];

  mobile.system.type = "android";

  mobile.usb.mode = "gadgetfs";
  # FIXME: attribute to sources.
  mobile.usb.idVendor  = "2717"; # Xiaomi Communications Co., Ltd.
  mobile.usb.idProduct = "FF80"; # Mi/Redmi series (RNDIS)

  mobile.usb.gadgetfs.functions = {
    rndis = "rndis_bam.rndis";
    adb = "ffs.adb";
  };
}
