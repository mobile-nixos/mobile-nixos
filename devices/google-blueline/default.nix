{ config, lib, pkgs, ... }:

{
  mobile.device.name = "google-blueline";
  mobile.device.info = rec {
    name = "Google Pixel 3";
    # TODO : make kernel part of options.
    kernel = pkgs.callPackage ./kernel { kernelPatches = pkgs.defaultKernelPatches; };

    format_version = "0";
    manufacturer = "Google";
    codename = "google-blueline";
    date = "";
    dtb = "";
    modules_initfs = "";
    arch = "aarch64";
    keyboard = "false";
    external_storage = "true";
    screen_width = "2160";
    screen_height = "1080";
    dev_touchscreen = "";
    dev_touchscreen_calibration = "";
    dev_keyboard = "";
    flash_method = "fastboot";

    kernel_cmdline = "console=ttyMSM0,115200n8 androidboot.console=ttyMSM0 printk.devkmsg=on msm_rtb.filter=0x237 ehci-hcd.park=3 service_locator.enable=1 firmware_class.path=/vendor/firmware cgroup.memory=nokmem lpm_levels.sleep_disabled=1 usbcore.autosuspend=7 androidboot.fastboot=1 buildvariant=eng";

    generate_bootimg = "true";
    bootimg_qcdt = false;
    flash_offset_base = "0x00000000";
    flash_offset_kernel = "0x00008000";
    flash_offset_ramdisk = "0x01000000";
    flash_offset_second = "0x00f00000";
    flash_offset_tags = "0x00000100";
    flash_pagesize = "4096";
  };

  mobile.hardware = {
    soc = "qualcomm-sdm845";
    # 4GB for the specific revision supported.
    # When this will be actually used, this may be dropped to 3, and/or
    # document all ram types as a list and work with min/max of those.
    ram = 1024 * 4;
    screen = {
      width = 2160; height = 2880;
    };
  };

  mobile.system.type = "android";

  # FIXME: properly use the partlabel instead.
  # This is a huge hack and should be dropped ASAP.
  fileSystems."/".device = lib.mkForce "/dev/sda13";
}
