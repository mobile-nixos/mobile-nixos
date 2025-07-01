{ config, lib, pkgs, ... }:


let
  qcom-video-firmware =
    pkgs.runCommand "potter-firmware" {} ''
      dir=$out/lib/firmware/qcom
      mkdir -p $dir
      cp  ${pkgs.linux-firmware}/lib/firmware/qcom/a530* $dir
    ''
  ;
in
{

  mobile.device.name = "lenovo-cd-18781y";
  mobile.device.identity = {
    name = "ThinkSmart View";
    manufacturer = "Lenovo";
  };
  mobile.device.supportLevel = "supported";
  mobile.hardware = {
    soc = "qualcomm-msm8953";
    screen = {
      # Panel is portrait CW compared to keyboard attachment.
      width = 800; height = 1280;
    };
  };

  mobile.boot.stage-1.firmware = [
    qcom-video-firmware
  ];

  mobile.boot.stage-1.kernel = {
    package = pkgs.callPackage ./kernel { };
    modular = true;
    modules = [
      "qcom-pon"                # power and volume down keys
      "panel-lenovo-cd-18781y-ft8201"
      "panel-lenovo-cd-18781y-hx83100a"
      "panel-lenovo-cd-18781y-jd9365"
      "msm" # DRM module
    ];
  };

  mobile.device.enableFirmware = false;

  mobile.system.type = "android";
  mobile.system.android = {
    bootimg.flash = {
      offset_base = "0x80000000";
      offset_kernel = "0x00008000";
      offset_ramdisk = "0x01000000";
      offset_second = "0x00f00000";
      offset_tags = "0x00000100";
      pagesize = "2048";
    };
    appendDTB = [
      "dtbs/qcom/apq8053-lenovo-cd-18781y.dtb"
    ];
  };

  mobile.system.android.flashingMethod = "lk2nd";
  mobile.usb.mode = "gadgetfs";
  # The identifiers used here serve as a compatible well-known identifier.
  mobile.usb.idVendor = lib.mkDefault "18D1"; # Google
  mobile.usb.idProduct = lib.mkDefault "4EE7"; # something not "D001", to distinguish nixos from fastboot/lk2nd

  mobile.usb.gadgetfs.functions = {
      rndis = "rndis.usb0";
      adb = "ffs.adb";
  };
}
