{ config, lib, pkgs, ... }:

{
  mobile.device.name = "google-marlin";
  mobile.device.info = rec {
    name = "Google Pixel XL";
    # TODO : make kernel part of options.
    kernel = pkgs.callPackage ./kernel { kernelPatches = pkgs.defaultKernelPatches; };

    format_version = "0";
    manufacturer = "Google";
    codename = "google-marlin";
    date = "";
    dtb = "";
    modules_initfs = "";
    arch = "aarch64";
    keyboard = "false";
    external_storage = "true";
    screen_width = "1440";
    screen_height = "2880";
    dev_touchscreen = "";
    dev_touchscreen_calibration = "";
    dev_keyboard = "";
    flash_method = "fastboot";

    kernel_cmdline = "console=ttyHSL0,115200,n8 androidboot.console=ttyHSL0 androidboot.hardware=marlin user_debug=31 ehci-hcd.park=3 lpm_levels.sleep_disabled=1 cma=32M@0-0xffffffff loop.max_part=7 buildvariant=eng";

    generate_bootimg = true;
    bootimg_qcdt = false;
    flash_offset_base = "0x80000000";
    flash_offset_kernel = "0x00008000";
    flash_offset_ramdisk = "0x01000000";
    flash_offset_second = "0x00f00000";
    flash_offset_tags = "0x00000100";
    flash_pagesize = "4096";

    # This device adds skip_initramfs to cmdline for normal boots
    boot_as_recovery = true;

    ab_partitions = true;
  };

  mobile.hardware = {
    soc = "qualcomm-msm8996";
    ram = 1024 * 4;
    screen = {
      width = 1440; height = 2880;
    };
  };

  mobile.usb.mode = "android_usb";
  # Google
  mobile.usb.idVendor = "18D1";
  # "Pixel" rndis+adb
  mobile.usb.idProduct = "4EE4";

  mobile.system.type = "android";
}
