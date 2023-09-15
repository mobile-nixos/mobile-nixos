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
  mobile.device.name = "motorola-potter";
  mobile.device.identity = {
    name = "Moto G5 Plus";
    manufacturer = "Motorola";
  };
  # The boot image is currently too big to fit.
  mobile.device.supportLevel = "broken";

  mobile.hardware = {
    soc = "qualcomm-msm8953";
    ram = 1024 * 2;
    screen = {
      width = 1080; height = 1920;
    };
  };

  mobile.boot.stage-1.firmware = [
    qcom-video-firmware
  ];

  mobile.boot.stage-1.kernel = {
    package = pkgs.callPackage ./kernel { };
    modular = true;
    modules = [
      # These are modules because postmarketos builds them as
      # modules.  Excepting that you only need one of the two
      # panel modules (hardware-dependent) it might make more
      # sense to build them monolithically. Unless you want to
      # run your phone headlessly ...
      "rmi_i2c"                 # touchscreen driver
      "qcom-pon"                # power and volume down keys
      "panel-boe-bs052fhm-a00-6c01"
      "panel-tianma-tl052vdxp02"
      "msm"                     # DRM module
    ];
  };

  # in your configuration.nix hardware.firmware, in addition to this
  # package you will probably need pkgs.linux-firmware, pkgs.wireless-regdb
  mobile.device.firmware = pkgs.callPackage ./firmware {};
  # Firmware is not enabled by default since it requires manually providing unredistributable files.
  mobile.device.enableFirmware = false;

  mobile.system.android.device_name = "potter";
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
      "dtbs/qcom/sdm625-motorola-potter.dtb"
    ];
  };

  # The boot partition on this phone is 16MB, so use `xz` compression
  # as smaller than gzip
  mobile.boot.stage-1.compression = lib.mkDefault "xz";

  mobile.usb = {
    mode = "gadgetfs";
    idVendor = "18D1";  # Google
    idProduct = "4EE7"; # something not "D001", to distinguish nixos from fastboot/lk2nd

    gadgetfs.functions = {
      rndis = "rndis.usb0";
      adb = "ffs.adb";
    };
  };

  mobile.system.type = "android";
  mobile.system.android.flashingMethod = "lk2nd";

  mobile.kernel.structuredConfig = [
    (helpers: with helpers; {
      CC_OPTIMIZE_FOR_PERFORMANCE = no;
      CC_OPTIMIZE_FOR_SIZE = yes;
    })
  ];
}
