{ config, lib, pkgs, options, ... }:

let
  cfg = config.mobile.quirks.qualcomm.q6voiced;
  inherit (lib)
    mdDoc
    mkIf
    mkEnableOption
    mkOption
    types
  ;
in
{
  options.mobile.quirks.qualcomm.q6voiced = {
    enable = mkEnableOption "userspace daemon for QDSP6 voice call audio driver";
    card = mkOption {
      type = types.int;
      description = mdDoc "ALSA sound card. Use {manpage}`alsactl info` to find";
    };
    device = mkOption {
      type = types.int;
      description = mdDoc "Modem audio device, e.g. `VoiceMMode1`";
    };
  };
  config = mkIf (cfg.enabled) {
    systemd.services = {
      q6voiced = {
        after = [ "ModemManager.service" "dbus.socket" ];
        wantedBy = [ "ModemManager.service" ];
        requires = [ "dbus.socket" ];
        serviceConfig.ExecStart = "${pkgs.q6voiced}/bin/q6voiced hw:${toString cfg.card},${toString cfg.device}";
      };
    };
  };
}
