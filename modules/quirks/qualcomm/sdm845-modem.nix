{ config, lib, pkgs, ... }:

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
        Enable this on a device sdm845 device for modem support
      '';
    };
  };
  config = mkIf (cfg.sdm845-modem.enable) {
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
