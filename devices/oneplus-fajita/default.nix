{ config, lib, pkgs, ... }:

{
  mobile.device.name = "oneplus-fajita";
  mobile.device.identity = {
    name = "OnePlus 6T";
    manufacturer = "OnePlus";
  };

  mobile.hardware = {
    soc = "qualcomm-sdm845";
    ram = 1024 * 8;
    screen = {
      width = 1080; height = 2340;
    };
  };

  mobile.boot.stage-1 = {
    kernel.package = pkgs.callPackage ./kernel { };
    firmware = [
      config.mobile.device.firmware
    ];
  };


  mobile.device.firmware = pkgs.callPackage ./firmware {};

  mobile.system.android.device_name = "OnePlus6T";
  mobile.system.android = {
    ab_partitions = true;
    bootimg.flash = {
      offset_base = "0x00000000";
      offset_kernel = "0x00008000";
      offset_ramdisk = "0x01000000";
      offset_second = "0x00f00000";
      offset_tags = "0x00000100";
      pagesize = "4096";
    };
  };

  boot.kernelParams = [
    "console=tty0"
    "panic=10"
  ];

  mobile.usb.mode = "gadgetfs";
  # Google
  mobile.usb.idVendor = "18D1";
  # "Nexus 4"
  mobile.usb.idProduct = "D001";

  mobile.system.type = "android";

  hardware.enableRedistributableFirmware = true;
  hardware.firmware = let
    prefixFirmware = pkgs.runCommand "fw-override" {} ''
        mkdir -p $out/lib
        cp -r ${fw}/lib/firmware/postmarketos $out/lib/firmware
    '';
    fw = config.mobile.device.firmware;
  in lib.mkBefore [ prefixFirmware fw ];


  mobile.usb.gadgetfs.functions = {
    adb = "ffs.adb";
    rndis = "rndis.usb0";
  };

  systemd.services = {
    rmtfs = rec {
      wantedBy = [ "multi-user.target" ];
      requires = [ "qrtr-ns.service" ];
      after = requires;
      serviceConfig = {
        ExecStart = "${pkgs.rmtfs}/bin/rmtfs -r -P -s";
        Restart = "always";
        RestartSec = "1";
      };
    };
    qrtr-ns = rec {
      serviceConfig = {
        ExecStart = "${pkgs.qrtr}/bin/qrtr-ns -f 1";
        Restart = "always";
      };
    };
    tqftpserv = rec {
      wantedBy = [ "multi-user.target" ];
      requires = [ "qrtr-ns.service" ];
      after = requires;
      serviceConfig = {
        ExecStart = "${pkgs.tqftpserv}/bin/tqftpserv";
        Restart = "always";
      };
    };
    pd-mapper = rec {
      wantedBy = [ "multi-user.target" ];
      requires = [ "qrtr-ns.service" ];
      after = requires;
      serviceConfig = {
        ExecStart = "${pkgs.pd-mapper}/bin/pd-mapper";
        Restart = "always";
      };
    };
  };


  services.udev.extraRules = ''
    SUBSYSTEM=="input", KERNEL=="event*", ENV{ID_INPUT}=="1", SUBSYSTEMS=="input", ATTRS{name}=="pmi8998_haptics", TAG+="uaccess", ENV{FEEDBACKD_TYPE}="vibra"
  '';
}
