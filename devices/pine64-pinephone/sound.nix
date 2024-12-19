# PinePhone UCM files
#
# A hack to avoid mass rebuilds of packages that depend on
# alsaLib.

{ config, lib, ... }:

let
  # From https://gitlab.manjaro.org/manjaro-arm/packages/community/phosh/alsa-ucm-pinephone
  ucm2 = "${./ucm2}";
in {
  config = lib.mkMerge [
    {
      environment.variables.ALSA_CONFIG_UCM2 = ucm2;
    }
    (lib.mkIf (config.hardware.pulseaudio.enable && !config.hardware.pulseaudio.systemWide) {
      systemd.user.services.pulseaudio.environment.ALSA_CONFIG_UCM2 = ucm2;
    })
    (lib.mkIf (config.hardware.pulseaudio.enable && config.hardware.pulseaudio.systemWide) {
      systemd.services.pulseaudio.environment.ALSA_CONFIG_UCM2 = ucm2;
    })
  ];
}
