{ config, lib, pkgs, ... }:

{
  mobile.device.name = "google-walleye";
  mobile.device.info = rec {
    name = "Google Pixel 2";
    # TODO : make kernel part of options.
    kernel = pkgs.callPackage ./kernel { kernelPatches = pkgs.defaultKernelPatches; };

    format_version = "0";
    manufacturer = "Google";
    codename = "google-walleye";
    date = "";
    dtb = "";
    modules_initfs = "";
    arch = "aarch64";
    keyboard = "false";
    external_storage = "true";
    screen_width = "1080";
    screen_height = "1920";
    dev_touchscreen = "";
    dev_touchscreen_calibration = "";
    dev_keyboard = "";
    flash_method = "fastboot";

    kernel_cmdline = lib.concatStringsSep " " [
      # From TWRP
      "androidboot.hardware=walleye"
      "androidboot.console=ttyMSM0"
      "lpm_levels.sleep_disabled=1"
      "user_debug=31"
      "msm_rtb.filter=0x37"
      "ehci-hcd.park=3"
      "service_locator.enable=1"
      "swiotlb=2048"
      "firmware_class.path=/vendor/firmware"
      "loop.max_part=7"
      "raid=noautodetect"
      "androidboot.fastboot=1"
      "buildvariant=eng"

      # Using `quiet` fixes early framebuffer init, for stage-1
      "quiet"
    ];

    generate_bootimg = "true";
    bootimg_qcdt = false;
    flash_offset_base = "0x00000000";
    flash_offset_kernel = "0x00008000";
    flash_offset_ramdisk = "0x01000000";
    flash_offset_second = "0x00f00000";
    flash_offset_tags = "0x00000100";
    flash_pagesize = "4096";

    # This device adds skip_initramfs to cmdline for normal boots
    boot_as_recovery = true;

    ab_partitions = true;
    vendor_partition = "/dev/disk/by-partlabel/vendor_a";
    gadgetfs.functions = {
      rndis = "gsi.rndis";
      # FIXME: This is the right function name, but doesn't work.
      # adb = "ffs.usb0";
    };
  };

  mobile.hardware = {
    soc = "qualcomm-msm8998";
    ram = 1024 * 4;
    screen = {
      width = 1080; height = 1920;
    };
  };

  mobile.system.type = "android";

  mobile.usb.mode = "gadgetfs";
  # Google
  mobile.usb.idVendor = "18D1";
  # "Nexus 4"
  mobile.usb.idProduct = "D001";
}
