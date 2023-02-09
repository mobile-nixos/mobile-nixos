{ config, lib, pkgs, ... }:

{
  mobile.device.name = "nokia-argon";
  mobile.device.identity = {
    name = "8110 4G";
    manufacturer = "Nokia";
  };

  mobile.hardware = {
    soc = "qualcomm-msm8905";
    ram = 512;
    screen = {
      width = 240; height = 320;
    };
  };

  boot.kernelParams = [
    # TODO: option to enable serial console.
    "earlycon"
    "console=ttyMSM0,115200"
  ];

  mobile.boot.stage-1 = {
    kernel.package = pkgs.callPackage ./kernel { };
  };

  mobile.system.android.bootimg = {
    flash = {
      offset_base = "0x80000000";
      offset_kernel = "0x00008000";
      offset_ramdisk = "0x02700000";
      offset_second = "0x00f00000";
      offset_tags = "0x02500000";
      pagesize = "2048";
    };
  };
  mobile.system.android.appendDTB = [
    "dtbs/qcom-msm8905-nokia-argon.dtb"
  ];

  mobile.usb.mode = "gadgetfs";
  # ID used in fastboot... not actually "correct"
  mobile.usb.idVendor = "18d1";
  mobile.usb.idProduct = "d00d";

  mobile.usb.gadgetfs.functions = {
    adb = "ffs.adb";
    mass_storage = "mass_storage.0";
    rndis = "rndis.usb0";
  };

  mobile.system.type = "android";

  mobile.boot.stage-1.compression = lib.mkDefault "xz";

  mobile.device.firmware = pkgs.callPackage ./firmware {};
  mobile.boot.stage-1.firmware = [
    config.mobile.device.firmware
  ];

  mobile.kernel.structuredConfig = [
    (helpers: with helpers; {
      # With the vendor kernel, setting to =n fails the build
      FW_LOADER_USER_HELPER = lib.mkForce yes;
    })
  ];
}
