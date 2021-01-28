{ pkgs, ... }:

{
  mobile.device.name = "sony-pioneer";
  mobile.device.identity = {
    name = "Xperia XA2";
    manufacturer = "Sony";
  };

  mobile.hardware = {
    soc = "qualcomm-sdm660";
    ram = 1024 * 3;
    screen = {
      width = 1080; height = 1920;
    };
  };

  mobile.boot.stage-1 = {
    kernel.package = pkgs.callPackage ./kernel { };
  };

  mobile.system.android = {
    ab_partitions = true;

    bootimg.flash = {
      offset_base = "0x00000000";
      offset_kernel = "0x00008000";
      offset_ramdisk = "0x01000000";
      offset_second = "0x00f00000";
      offset_tags = "0x00000100";
      pagesize = "4096";
    };
  };

  mobile.system.vendor.partition = "/dev/disk/by-partlabel/vendor_a";

  boot.kernelParams = [
    # Extracted from an Android boot image
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
    "panic_on_err=1"
    "loop.max_part=7"
    "buildvariant=user"
    "veritykeyid=id:7178c839cde12f22cc9da21c692827e699dff45b"
  ];

  mobile.system.type = "android";

  mobile.usb.mode = "gadgetfs";

  # Sony
  mobile.usb.idVendor = "0FCE";
  # Xperia XA2
  mobile.usb.idProduct = "71F7";

  mobile.usb.gadgetfs.functions = {
    rndis = "rndis_bam.rndis";
    adb = "ffs.adb";
  };

}
