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
    screen = {
      # Panel is portrait CW compared to keyboard attachment.
      width = 800; height = 1280;
    };
  };

  mobile.hardware = {
    soc = "qualcomm-msm8953";
  };

  mobile.boot.stage-1.kernel = {
    package = pkgs.callPackage ./kernel { };
    modular = true;
    modules = [
      # These are modules because postmarketos builds them as
      # modules.  Excepting that you only need one of the two
      # panel modules (hardware-dependent) it might make more
      # sense to build them monolithically. Unless you want to
      # run your phone headlessly ...
      "qcom-pon"                # power and volume down keys
      "lenovo-cd-18781y-ft8201"
      "lenovo-cd-18781y-hx83100a"
#       "lenovo-cd-18781y-jd9365"
    ];
  };

  mobile.device.enableFirmware = false;

  # Note: on devices it's highly likely no firmware is required during stage-1.
  # DRM *should* work fine without firmware.
  # Modems and such will pick them back up in stage-2.
  # Even though, we're eagerly adding firmware files that fit.
  # This is a workaround for non-modular kernels wanting to load the adsp firmware during stage-1.
#   mobile.boot.stage-1.firmware = [
#     (pkgs.runCommand "initrd-firmware" {} ''
#       cp -vrf ${config.mobile.device.firmware} $out
#       chmod -R +w $out
#       # Big file, fills and breaks stage-1
#       rm -v $out/lib/firmware/qcom/sdm845/*/modem.mbn
#
#       # Copy extra a630 firmware from linux-firmware
#       cp -vf ${pkgs.linux-firmware}/lib/firmware/qcom/{a630_sqe.fw,a630_gmu.bin} $out/lib/firmware/qcom
#     '')
#   ];


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
  mobile.usb.idProduct = lib.mkDefault "D001"; # "Nexus 4"

  mobile.usb.gadgetfs.functions = {
    adb = "ffs.adb";
    mass_storage = "mass_storage.0";
    rndis = "rndis.usb0";
  };

#   mobile.quirks.qualcomm.sdm845-modem.enable = true;
/*
  services.udev.extraRules = ''
    SUBSYSTEM=="input", KERNEL=="event*", ENV{ID_INPUT}=="1", SUBSYSTEMS=="input", ATTRS{name}=="pmi8998_haptics", TAG+="uaccess", ENV{FEEDBACKD_TYPE}="vibra"
  '';*/
}
