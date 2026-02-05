{ config, lib, pkgs, ... }:

{
  imports = [
    ./sound.nix
  ];

  mobile.hardware = {
    soc = "qualcomm-sdm845";
  };

  mobile.boot.stage-1 = {
    compression = "xz";
    kernel.package = (pkgs.callPackage ./kernel { });

    # Enable microhop-based initramfs
    microhop = {
      enable = true;
      microhop = pkgs.microhop;

      # Display and panel modules (required for DRM/graphics)
      modules = [
        # DMA support (CRITICAL - needed for GPU and other devices)
        "gpi"
        # DRM core and MSM display driver
        "msm"
        "panel-lg-sw43408"
        # DRM bridge and aux support
        "aux_bridge"
        "display_connector"
        # Additional DRM helpers
        "drm_display_helper"
        "drm_kms_helper"
        # Input devices (touchscreen support)
        "rmi_core"
        "rmi_i2c"
        # Input misc
        "uinput"
      ];

      # Disk configuration for root filesystem
      # Format: "device_identifier: fstype,mountpoint,mode"
      # Supported identifiers: label=NAME, uuid=UUID, or /dev/path
      # Using UUID to match the partition ID defined in modules/rootfs.nix
      disks = [
        "uuid=44444444-4444-4444-8888-888888888888: ext4,/,rw"
      ];

      # Mask the bootloader's root parameter
      # The Android bootloader passes a hardcoded PARTUUID at runtime that doesn't
      # match our filesystem. By masking "root" from cmdline, microhop will use
      # the disk configuration above instead.
      mask_cmdline = [ "root" ];

      # Filesystem types to support
      filesystems = [ "ext4" ];

      # Block device drivers
      blockDevices = [ "ufshcd" "ufs-qcom" ];

      logLevel = "debug";
    };
  };

  hardware.enableRedistributableFirmware = false;

  mobile.boot.stage-1.microhop.firmwareFiles = lib.mkIf config.mobile.boot.stage-1.microhop.enable (
    let
      deviceCodename = lib.last (lib.splitString "-" config.mobile.device.name);
    in
    [
      "${pkgs.linux-firmware.zstd}/lib/firmware/qcom/a630_sqe.fw.zst"
      "${pkgs.linux-firmware.zstd}/lib/firmware/qcom/a630_gmu.bin.zst"
      "${config.mobile.device.firmware}/lib/firmware/qcom/sdm845/${config.mobile.device.identity.manufacturer}/${deviceCodename}/a630_zap.mbn.zst"
    ]
  );

  mobile.system.type = "android";
  mobile.system.android = {
    # Assumed all SDM845 devices use A/B
    ab_partitions = lib.mkDefault true;
    # Assumed all SDM845 devices can boot with the same options.
    bootimg.flash = {
      offset_base = "0x00000000";
      offset_kernel = "0x00008000";
      offset_ramdisk = "0x01000000";
      offset_second = "0x00000000";
      offset_tags = "0x00000100";
      pagesize = "4096";
    };
    appendDTB = lib.mkDefault [
      "dtbs/qcom/sdm845-${config.mobile.device.name}.dtb"
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

  mobile.quirks.qualcomm.sdm845-modem.enable = true;

  services.udev.extraRules = ''
    SUBSYSTEM=="input", KERNEL=="event*", ENV{ID_INPUT}=="1", SUBSYSTEMS=="input", ATTRS{name}=="pmi8998_haptics", TAG+="uaccess", ENV{FEEDBACKD_TYPE}="vibra"
  '';
}
