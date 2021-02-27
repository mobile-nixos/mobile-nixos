{ config, lib, pkgs, ... }:

{
  mobile.device.name = "xiaomi-tissot";
  mobile.device.identity = {
    name = "A1";
    manufacturer = "Xiaomi";
  };

  mobile.hardware = {
    soc = "qualcomm-msm8953";
    ram = 1024 * 4;
    screen = {
      width = 1080; height = 1920;
    };
  };

  mobile.boot.stage-1 = {
    kernel.package = pkgs.callPackage ./kernel { };
  };

  mobile.usb = {
    mode = "android_usb";
    idVendor = "18d1";
    idProduct = "d001";
  };

  mobile.system.android.device_name = "tissot";
  mobile.system.android = {
    bootimg.flash = {
      offset_base = "0x80000000";
      offset_kernel = "0x00008000";
      offset_second = "0x00f00000";
      offset_ramdisk = "0x01000000";
      offset_tags = "0x00000100";
      pagesize = "2048";
    };
  };

  boot.kernelParams = [
    "androidboot.hardware=qcom"
    "msm_rtb.filter=0x237"
    "ehci-hcd.park=3"
    "lpm_levels.sleep_disabled=1"
    "androidboot.bootdevice=7824900.sdhci"
    "earlycon=msm_hsl_uart,0x78af000"
    "androidboot.selinux=permissive"
    "buildvariant=eng"
  ];

  mobile.system.type = "android";
}
