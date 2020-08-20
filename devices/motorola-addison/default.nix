{ config, lib, pkgs, ... }:

{
  mobile.device.name = "motorola-addison";
  mobile.device.identity = {
    name = "Moto Z Play";
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

  mobile.device.firmware = pkgs.callPackage ./firmware {};

  mobile.system.android.bootimg = {
    dt = "${config.mobile.boot.stage-1.kernel.package}/dtbs/motorola-addison.img";
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

  mobile.usb.mode = "android_usb";
  # Google
  mobile.usb.idVendor = "18D1";
  # "Nexus 4"
  mobile.usb.idProduct = "D001";

  mobile.system.type = "android";

  mobile.quirks.qualcomm.fb-notify.enable = true;

  mobile.quirks.qualcomm.wcnss-wlan.enable = true;
}
