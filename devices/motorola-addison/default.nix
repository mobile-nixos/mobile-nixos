{ config, lib, pkgs, ... }:

{
  mobile.device.name = "motorola-addison";
  mobile.device.identity = {
    name = "Moto Z Play";
    manufacturer = "Motorola";
  };

  mobile.device.info = rec {
    kernel_cmdline = lib.concatStringsSep " " [
      "androidboot.console=ttyHSL0"
      "androidboot.hardware=qcom"
      "user_debug=30"
      "msm_rtb.filter=0x237"
      "ehci-hcd.park=3"
      "androidboot.bootdevice=7824900.sdhci"
      "lpm_levels.sleep_disabled=1"
      "vmalloc=350M"
      "buildvariant=userdebug"
    ];
    bootimg_qcdt = true;
    flash_offset_base = "0x80000000";
    flash_offset_kernel = "0x00008000";
    flash_offset_ramdisk = "0x01000000";
    flash_offset_second = "0x00f00000";
    flash_offset_tags = "0x00000100";
    flash_pagesize = "2048";
    # TODO : make kernel part of options.
    kernel = pkgs.callPackage ./kernel { kernelPatches = pkgs.defaultKernelPatches; };
    dtb = "${kernel}/dtbs/motorola-addison.img";
  };
  mobile.hardware = {
    soc = "qualcomm-msm8953";
    ram = 1024 * 3;
    screen = {
      width = 1080; height = 1920;
    };
  };

  mobile.usb.mode = "android_usb";
  # Google
  mobile.usb.idVendor = "18D1";
  # "Nexus 4"
  mobile.usb.idProduct = "D001";

  mobile.system.type = "android";
}
