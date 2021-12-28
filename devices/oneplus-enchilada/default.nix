{ config, lib, pkgs, ... }:

{
  mobile.device.name = "oneplus-enchilada";
  mobile.device.identity = {
    name = "OnePlus 6";
    manufacturer = "OnePlus";
  };

  mobile.hardware = {
    soc = "qualcomm-sdm845";
    ram = 1024 * 8;
    screen = {
      width = 1080; height = 2280;
    };
  };

  mobile.boot.stage-1 = {
    compression = "xz";
    kernel.package = pkgs.callPackage ./kernel { };
    firmware = [
      config.mobile.device.firmware
    ];
  };


  mobile.device.firmware = pkgs.callPackage ./firmware {};

  mobile.system.android.device_name = "OnePlus6";
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
  ];

  mobile.usb.mode = "gadgetfs";
  # Google
  mobile.usb.idVendor = "18D1";
  # "Nexus 4"
  mobile.usb.idProduct = "D001";

  mobile.system.type = "android";

  hardware.enableRedistributableFirmware = true;
  hardware.firmware = lib.mkBefore [ config.mobile.device.firmware ];


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
    msm-modem-uim-selection = {
      enable = true;
      before = [ "ModemManager.service" ];
      wantedBy = [ "ModemManager.service" ];
      path = with pkgs; [ libqmi gawk gnugrep ];
      script = ''
        QMICLI_MODEM="qmicli --silent -pd qrtr://0"
        QMI_CARDS=$($QMICLI_MODEM --uim-get-card-status)
        if ! printf "%s" "$QMI_CARDS" | grep -Fq "Primary GW:   session doesn't exist"
        then
            $QMICLI_MODEM --uim-change-provisioning-session='activate=no,session-type=primary-gw-provisioning' > /dev/null
        fi
        FIRST_PRESENT_SLOT=$(printf "%s" "$QMI_CARDS" | grep "Card state: 'present'" -m1 -B1 | head -n1 | cut -c7-7)
        FIRST_PRESENT_AID=$(printf "%s" "$QMI_CARDS" | grep "usim (2)" -m1 -A3 | tail -n1 | awk '{print $1}')
        $QMICLI_MODEM --uim-change-provisioning-session="slot=$FIRST_PRESENT_SLOT,activate=yes,session-type=primary-gw-provisioning,aid=$FIRST_PRESENT_AID" > /dev/null
      '';
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
    };
  };


  services.udev.extraRules = ''
    SUBSYSTEM=="input", KERNEL=="event*", ENV{ID_INPUT}=="1", SUBSYSTEMS=="input", ATTRS{name}=="pmi8998_haptics", TAG+="uaccess", ENV{FEEDBACKD_TYPE}="vibra"
  '';
}
