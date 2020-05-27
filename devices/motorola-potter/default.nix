{ config, lib, pkgs, ... }:

{
  mobile.device.name = "motorola-potter";
  mobile.device.identity = {
    name = "Moto G5 Plus";
    manufacturer = "Motorola";
  };

  mobile.hardware = {
    soc = "qualcomm-msm8953";
    ram = 1024 * 3;
    screen = {
      width = 1080; height = 1920;
    };
  };

  mobile.boot.stage-1 = {
    kernel.package = pkgs.callPackage ./kernel { kernelPatches = pkgs.defaultKernelPatches; };
  };

  mobile.system.android.bootimg = {
    dt = "${config.mobile.boot.stage-1.kernel.package}/dtbs/motorola-potter.img";
    flash = {
      offset_base = "0x80000000";
      offset_kernel = "0x00008000";
      offset_ramdisk = "0x01000000";
      offset_second = "0x00f00000";
      offset_tags = "0x00000100";
      pagesize = "2048";
    };
  };

  boot.kernelParams = [
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

  mobile.usb = {
    # Dan is not sure what this is for, given that it seems to be
    # set to the Nexus 4 id on a variety of other devices which aren't that
    mode = "android_usb";
    # 18d1:4ee7 Google Inc. XT1685
    idVendor = "18D1";
    idProduct = "4EE7";
  }

  mobile.system.type = "android";
}
