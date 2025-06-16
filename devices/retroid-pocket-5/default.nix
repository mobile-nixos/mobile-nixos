{
  config,
  lib,
  pkgs,
  ...
}:

{
  imports = [
    ../families/sdm845-mainline
  ];

  mobile.device.name = "retroid-pocket-5";
  mobile.device.identity = {
    name = "Retroid Pocket 5";
    manufacturer = "Moorechip";
  };
  mobile.device.supportLevel = "best-effort";

  mobile.hardware = {
    ram = 1024 * 8;
    screen = {
      width = 1920;
      height = 1080;
    };
  };

  boot.kernelParams = [
    "clk_ignore_unused"
    "pd_ignore_unused"
    "arm64.nopauth"
    "efi=noruntime"
    "console=ttyMSM0,115200n8"
    "fbcon=rotate:3"
  ];

  boot.kernelModules = [ "panel-ddic-ch13726a" ];
  boot.initrd.availableKernelModules = [
    "panel-ddic-ch13726a"
    "qcom_spmi_haptics"
    "qcom_glink_smem"
    "qcom_smd"
    "qcom_common"
    "rpmhpd"
    "qcom_rpmh"
    "cmd-db"
  ];

  mobile.device.firmware = pkgs.callPackage ./firmware { };

  mobile.system.android.device_name = "Retroidp Pocket 5";
}
