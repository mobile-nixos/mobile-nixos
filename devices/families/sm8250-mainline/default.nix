{ config, lib, pkgs, ... }:

let
  qcomVideoFirmware = pkgs.runCommand "sm8250-video-firmware" {} ''
    dir=$out/lib/firmware/qcom
    mkdir -p $dir
    cp -v ${pkgs.linux-firmware}/lib/firmware/qcom/a650* $dir
  '';

  deviceFirmware = lib.optional (config.mobile.device.enableFirmware && config.mobile.device.firmware != null) (
    pkgs.runCommand "sm8250-device-initrd-firmware" {} ''
      cp -vrf ${config.mobile.device.firmware} $out
      chmod -R +w $out
    ''
  );
in
{
  mobile.hardware = {
    soc = "qualcomm-sm8250";
  };

  mobile.boot.stage-1 = {
    compression = "xz";
    firmware = [ qcomVideoFirmware ] ++ deviceFirmware;
  };

  hardware.enableRedistributableFirmware = true;

  mobile.system.type = "android";
  mobile.system.android = {
    ab_partitions = lib.mkDefault true;
    bootimg.flash = {
      offset_base = "0x00000000";
      offset_kernel = "0x00008000";
      offset_ramdisk = "0x01000000";
      offset_second = "0x00f00000";
      offset_tags = "0x00000100";
      pagesize = "4096";
    };
    appendDTB = lib.mkDefault [
      "dtbs/qcom/sm8250-${config.mobile.device.name}.dtb"
    ];
  };

  mobile.usb.mode = "gadgetfs";
  mobile.usb.idVendor = lib.mkDefault "18D1"; # Google
  mobile.usb.idProduct = lib.mkDefault "D001"; # "Nexus 4"

  mobile.usb.gadgetfs.functions = {
    adb = "ffs.adb";
    mass_storage = "mass_storage.0";
    rndis = "rndis.usb0";
  };
}
