{ config, lib, pkgs, ... }:

# Based in part on device-samsung-serranove from pmbootstrap

# REVIEW(Krey): Please advice on how to handle these firmware requirements:
# * Requires a firmware for GPU/WiFi/BT/Modem/Video
# ** firmware-qcom-adreno-a300 -- Appears to be obtainable from linux-firmware: https://gitlab.com/postmarketOS/pmaports/-/commit/96f2ad2fac39bf9c38a822f5a4369adb3e2fdda2
# ** msm-firmware-loader -- https://gitlab.com/postmarketOS/pmaports/-/tree/master/main/msm-firmware-loader
# ** firmware-samsung-serranove-wcnss-nv -- https://gitlab.com/postmarketOS/pmaports/-/blob/master/device/community/firmware-samsung-serranove/APKBUILD

{
  mobile.device.name = "samsung-serranove";
  mobile.device.identity = {
    name = "Galaxy S4 Mini Value Edition";
    manufacturer = "Samsung";
  };

  # The hardware supports aarch64-*, but the firmware was never updated from armv7 -> Disfunctional GPU/WiFi/BT/Modem/Video on aarch64-*
  mobile.system.system = "armv7l-linux";

  mobile.hardware = {
    soc = "qualcomm-msm8916";
    ram = 1024 * 1.5;
    # The panel is wired backwards so renders as XY mirrored which needs to be managed in software (https://gitlab.com/postmarketOS/pmaports/-/issues/1340)
    screen = {
      width = 540; height = 960;
    };
  };

  # TODO(Krey): Figure out the firmware
  # mobile.boot.stage-1.firmware = [
  #   qcom-video-firmware
  # ];

  mobile.boot.stage-1.kernel = {
    package = pkgs.callPackage ./kernel { };
    modular = true; # REVIEW(Krey): Unsure..
    modules = [
      "panel-samsung-s6e88a0-ams427ap24"
      "msm" # DRM module
      "zinitix"
      "rt5033"
      "rt5033-charger"
    ];
  };

  # mobile.device.firmware = pkgs.callPackage ./firmware {};
  # Firmware is not enabled by default since it requires manually providing unredistributable files.
  mobile.device.enableFirmware = false;

  mobile.system.android.device_name = "samsung-serranove";
  mobile.system.android = {
    bootimg.flash = {
      offset_base = "0x80000000";
      offset_kernel = "0x00008000";
      offset_ramdisk = "0x02000000";
      offset_second = "0x00f00000";
      offset_tags = "0x01e00000";
      pagesize = "2048";
    };
    # appendDTB = [
    #   "dtbs/qcom/sdm625-motorola-potter.dtb"
    # ];
  };

  # RFC(krey->samueldr): The boot partition on this device is 225.7M, should we use this?
  # mobile.boot.stage-1.compression = lib.mkDefault "xz";

  mobile.usb = {
    mode = "gadgetfs"; # REVIEW(Krey): Unsure..
    idVendor = "0x04e8"; # Samsung Electronics Co., Ltd
    idProduct = "6860"; # something not "D001", to distinguish nixos from fastboot/lk2nd

    # REVIEW(Krey): Unsure..
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
