{ config, lib, pkgs, ... }:

{
  imports = [
    ./sound.nix
  ];

  mobile.hardware = {
    soc = "qualcomm-sm7325";
  };

  mobile.boot.stage-1 = {
    compression = "xz"; # Consider lz4 or zstd compression
    kernel.package = (pkgs.callPackage ./kernel { });
    kernel.modular = true; # Modular might be best
  };

  hardware.enableRedistributableFirmware = true;

  # Note: on devices it's highly likely no firmware is required during stage-1.
  # DRM *should* work fine without firmware.
  # Modems and such will pick them back up in stage-2.
  # Even though, we're eagerly adding firmware files that fit.
  # This is a workaround for non-modular kernels wanting to load the adsp firmware during stage-1.
  mobile.boot.stage-1.firmware = [
    (pkgs.runCommand "initrd-firmware" {} ''
      cp -vrf ${config.mobile.device.firmware} $out
      chmod -R +w $out
      # Big file, fills and breaks stage-1
      find $out/lib/firmware/qcom/sm7325/ -name "modem.mbn" -type f -delete

      # Copy extra a660 firmware from linux-firmware for the Adreno 642L? see PMOS
      cp -vf ${pkgs.linux-firmware}/lib/firmware/qcom/{a660_sqe.fw,a660_gmu.bin} $out/lib/firmware/qcom
    '')
  ];

  hardware.firmware = lib.mkBefore [ config.mobile.device.firmware ];

  mobile.system.type = "android";
  mobile.system.android = {
    # Assume all SM7325 devices use A/B
    ab_partitions = lib.mkDefault true;
    # Assumed all SM7325 devices can boot with the same options.
    bootimg.flash = {
      offset_base = "0x00000000";
      offset_kernel = "0x00008000";
      offset_ramdisk = "0x01000000";
      offset_second = "0x00000000";
      offset_tags = "0x00000100";
      pagesize = "4096";
    };
    appendDTB = lib.mkDefault [
      "dtbs/qcom/sm7325-${config.mobile.device.name}.dtb" # Maybe make the soc dynamic as well
    ];
  };

  mobile.usb.mode = "gadgetfs";
  # The identifiers used here serve as a compatible well-known identifier.
  mobile.usb.idVendor = lib.mkDefault "18D1"; # Google
  mobile.usb.idProduct = lib.mkDefault "D001"; # "Nexus 4"

  mobile.usb.gadgetfs.functions = {
    adb = "ffs.adb";
    mass_storage = "mass_storage.0";
    rndis = "rndis.usb0";
  };

  boot.kernelParams = lib.mkAfter [
    # is the n8 needed?
    # If this is not present, the system will fail to boot reliably.
    # TODO: investigate if this is true when UART is not enabled in fastboot.
    "console=ttyMSM0,115200n8"
  ];
}
