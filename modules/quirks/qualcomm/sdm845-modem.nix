{ config, lib, pkgs, options, ... }:

let
  cfg = config.mobile.quirks.qualcomm;
  inherit (lib) mkIf mkOption types;
in
{
  options.mobile = {
    quirks.qualcomm.sdm845-modem.enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Enable this on a mainline-based SDM845 device for modem support
      '';
    };
  };
  config = mkIf (cfg.sdm845-modem.enable) {
    # Makes platform-specific firmware files available in an uncompressed form at:
    # /run/current-system/sw/share/uncompressed-firmware/qcom/sdm845/
    # This is used by userspace components unaware of the possible xz compression.
    # See also: tqftpserv and pd-mapper patches.
    environment.pathsToLink = [ "share/uncompressed-firmware" ];
    # This package added to the environment will select a few firmware path to keep uncompressed.
    environment.systemPackages = [
      (pkgs.callPackage (
        { lib
        , runCommand
        , buildEnv
        , firmwareFilesList
        }:

        runCommand "sdm845-uncompressed-firmware-share" {
          firmwareFiles = buildEnv {
            name = "sdm845-uncompressed-firmware";
            paths = firmwareFilesList;
            pathsToLink = [
              "/lib/firmware/qcom/sdm845"
            ];
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
          ExecStart = "${pkgs.rmtfs}/bin/rmtfs -r -P -s";
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
      pd-mapper = {
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
