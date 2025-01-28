{ config, lib, pkgs, ... }:

{
  mobile.device.name = "motorola-harpia";
  mobile.device.identity = {
    name = "Moto G4 Play";
    manufacturer = "Motorola";
  };
  mobile.device.supportLevel = "broken";

  mobile.hardware = {
    soc = "qualcomm-msm8916";
    ram = 1024 ;
    screen = {
      width = 720; height = 1080;
    };
  };

  mobile.boot.stage-1.kernel = {
    package = pkgs.callPackage ./kernel { };
    modular = true;
    modules = [
      # "rmi_i2c"                 # touchscreen driver
      "panel-motorola-harpia-tianma"
      "msm"                     # DRM module
      "qcom_wcnss_pil"
      "wcn36xx"
    ];
  };

  # Device firmware is not added to hardware.firmware automatically as
  # the package needs an override to point it at the files copied from
  # the device. In your configuration.nix you will need something like
  #
  # hardware.firmware = [
  #   (config.mobile.device.firmware.override {
  #     modem = ./path/to/copy/of/modem;
  #   })
  #   pkgs.wireless-regdb
  # ];

  mobile.device = {
    firmware = pkgs.callPackage ./firmware {};
    enableFirmware = false;
  };

  mobile.system.android.device_name = "harpia";
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
      "dtbs/qcom/msm8916-motorola-harpia.dtb"
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
