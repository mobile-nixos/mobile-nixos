{ config, lib, pkgs, options, ... }:

let
  cfg = config.mobile.quirks.qualcomm;
  inherit (lib)
    any
    id
    mkIf
    mkOption
    optional
    types
  ;
  anyCompatible = any id [
    cfg.sdm845-modem.enable
    cfg.sc7180-modem.enable
  ];

  # Systems for which we read the partition directly.
  # TODO: This is likely the wrong abstraction.
  # Once we have more accrued knowledge, add a discrete option.
  rmtfsReadsPartition = any id [
    cfg.sdm845-modem.enable
  ];

  # TODO: figure out what PD mapper exactly is...
  # is it USB PD or something modem related?
  withPDMapper = any id [
    cfg.sdm845-modem.enable
  ];
in
{
  options.mobile = {
    quirks.qualcomm.sc7180-modem.enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Enable this on a mainline-based SC7180 device for modem/Wi-Fi support
      '';
    };
    quirks.qualcomm.sdm845-modem.enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Enable this on a mainline-based SDM845 device for modem support
      '';
    };
  };
  config = mkIf (anyCompatible) {
    # Makes platform-specific firmware files available in an uncompressed form at:
    # /run/current-system/sw/share/uncompressed-firmware/qcom/sdm845/
    # This is used by userspace components unaware of the possible xz compression.
    # See also: tqftpserv and pd-mapper patches.
    environment.pathsToLink = [ "/share/uncompressed-firmware" ];
    # This package added to the environment will select a few firmware path to keep uncompressed.
    environment.systemPackages = [
      (pkgs.callPackage (
        { lib
        , runCommand
        , buildEnv
        , firmwareFilesList
        }:

        runCommand "qcom-modem-uncompressed-firmware-share" {
          firmwareFiles = buildEnv {
            name = "qcom-modem-uncompressed-firmware";
            paths = firmwareFilesList;
            pathsToLink = [
              "/lib/firmware/rmtfs"
            ]
              ++ optional cfg.sdm845-modem.enable "/lib/firmware/qcom/sdm845"
              ++ optional cfg.sc7180-modem.enable "/lib/firmware/qcom/sc7180-trogdor"
            ;
          };
        } ''
          PS4=" $ "
          (
          set -x
          mkdir -p $out/share/
          ln -s $firmwareFiles/lib/firmware/ $out/share/uncompressed-firmware
          )
        ''
      ) {
        # We have to borrow the pre `apply`'d list, thus `options...definitions`.
        # This is because the firmware is compressed in `apply` on `hardware.firmware`.
        firmwareFilesList = lib.flatten options.hardware.firmware.definitions;
      })
    ];

    systemd.services = {
      rmtfs = {
        wantedBy = [ "multi-user.target" ];
        requires = [ "qrtr-ns.service" ];
        after = [ "qrtr-ns.service" ];
        serviceConfig = {
          # https://github.com/andersson/rmtfs/blob/7a5ae7e0a57be3e09e0256b51b9075ee6b860322/rmtfs.c#L507-L541
          ExecStart = "${pkgs.rmtfs}/bin/rmtfs -s -r ${if rmtfsReadsPartition then "-P" else "-o /run/current-system/sw/share/uncompressed-firmware/rmtfs"}";
          Restart = "always";
          RestartSec = "1";
        };
      };
      qrtr-ns = {
        serviceConfig = {
          ExecStart = "${pkgs.qrtr}/bin/qrtr-ns -f 1";
          Restart = "always";
        };
      };
      tqftpserv = {
        wantedBy = [ "multi-user.target" ];
        requires = [ "qrtr-ns.service" ];
        after = [ "qrtr-ns.service" ];
        serviceConfig = {
          ExecStart = "${pkgs.tqftpserv}/bin/tqftpserv";
          Restart = "always";
        };
      };
      pd-mapper = mkIf withPDMapper {
        wantedBy = [ "multi-user.target" ];
        requires = [ "qrtr-ns.service" ];
        after = [ "qrtr-ns.service" ];
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
  };
}
