{ config, lib, pkgs, ... }:

{
  mobile.device.name = "asus-z00t";
  mobile.device.identity = {
    name = "Zenfone 2 Laser/Selfie (1080p)";
    manufacturer = "Asus";
  };

  mobile.hardware = {
    soc = "qualcomm-msm8939";
    # 3GB for the specific revision supported.
    # When this will be actually used, this may be dropped to 2, and/or
    # document all ram types as a list and work with min/max of those.
    ram = 1024 * 3;
    screen = {
      width = 1080; height = 1920;
    };
  };

  mobile.boot.stage-1 = {
    kernel.package = pkgs.callPackage ./kernel { };
  };

  mobile.device.firmware = pkgs.callPackage ./firmware {};

  mobile.system.android.device_name = "Z00T";
  mobile.system.android.bootimg = {
    flash = {
      offset_base = "0x10000000";
      offset_kernel = "0x00008000";
      offset_ramdisk = "0x02000000";
      offset_second = "0x00f00000";
      offset_tags = "0x00000100";
      pagesize = "2048";
    };
  };

  boot.kernelParams = [
    "androidboot.hardware=qcom"
    "ehci-hcd.park=3"
    "androidboot.bootdevice=7824900.sdhci"
    "lpm_levels.sleep_disabled=1"
    "androidboot.selinux=permissive"
  ];

  mobile.usb.mode = "android_usb";
  # Google
  mobile.usb.idVendor = "18D1";
  # "Nexus 4"
  mobile.usb.idProduct = "D001";

  mobile.system.type = "android";

  mobile.quirks.qualcomm.wcnss-wlan.enable = true;
}
