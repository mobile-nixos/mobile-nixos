# PineTab UCM files
#
# A hack to avoid mass rebuilds of packages that depend on
# alsaLib.
#
# UCM files taken from
# https://github.com/dreemurrs-embedded/Pine64-Arch/tree/02bf6ffafcab0a3c29e3b62b77b8e353d50d4706/PKGBUILDS/pine64/alsa-ucm-pinetab

{ config, lib, ... }:

let
  ucm2 = "${./ucm2}";
in {
  config = lib.mkMerge [
    {
      environment.variables.ALSA_CONFIG_UCM2 = ucm2;
    }
    (lib.mkIf (config.services.pulseaudio.enable && !config.services.pulseaudio.systemWide) {
      systemd.user.services.pulseaudio.environment.ALSA_CONFIG_UCM2 = ucm2;
    })
    (lib.mkIf (config.services.pulseaudio.enable && config.services.pulseaudio.systemWide) {
      systemd.services.pulseaudio.environment.ALSA_CONFIG_UCM2 = ucm2;
    })
  ];
}
