{ config, lib, pkgs, ... }:

{
  mobile.device.name = "xiaomi-tissot";
  mobile.device.identity = {
    name = "A1";
    manufacturer = "Xiaomi";
  };

  mobile.device.info = {
    # TODO : make kernel part of options.
    kernel = pkgs.callPackage ./kernel { kernelPatches = pkgs.defaultKernelPatches; };
  };

  mobile.hardware = {
    soc = "qualcomm-msm8953";
    ram = 1024 * 4;
    screen = {
      width = 1080; height = 1920;
    };
  };

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
