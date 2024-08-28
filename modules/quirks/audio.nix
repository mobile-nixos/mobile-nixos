{ config, lib, pkgs, ... }:

let
  cfg = config.mobile.quirks.audio;
  ucm-env = config.environment.variables.ALSA_CONFIG_UCM2;
in
{
  options.mobile.quirks.audio = {
    alsa-ucm-meld = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Combines the derivation output path share/alsa/ucm2/ with
        pkgs.alsa-ucm-conf and points ALSA to the result.
      '';
    };
  };

  config = lib.mkIf cfg.alsa-ucm-meld {
    environment.pathsToLink = [ "/share/alsa/ucm2" ];
    environment.systemPackages = [ pkgs.alsa-ucm-conf ];

    environment.variables.ALSA_CONFIG_UCM2 =
      "/run/current-system/sw/share/alsa/ucm2";

    # pulseaudio
    systemd.user.services.pulseaudio.environment.ALSA_CONFIG_UCM2 = ucm-env;
    systemd.services.pulseaudio.environment.ALSA_CONFIG_UCM2      = ucm-env;

    # pipewire
    systemd.user.services.pipewire.environment.ALSA_CONFIG_UCM2       = ucm-env;
    systemd.user.services.pipewire-pulse.environment.ALSA_CONFIG_UCM2 = ucm-env;
    systemd.user.services.wireplumber.environment.ALSA_CONFIG_UCM2    = ucm-env;
    systemd.services.pipewire.environment.ALSA_CONFIG_UCM2            = ucm-env;
    systemd.services.pipewire-pulse.environment.ALSA_CONFIG_UCM2      = ucm-env;
    systemd.services.wireplumber.environment.ALSA_CONFIG_UCM2         = ucm-env;
  };
}
