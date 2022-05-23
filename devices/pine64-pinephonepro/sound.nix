{ config, lib, pkgs, ... }:

{
  config = lib.mkMerge [
    (lib.mkIf config.sound.enable {
      environment.variables.ALSA_CONFIG_UCM2 = "${pkgs.pine64-alsa-ucm}";
    })
    (lib.mkIf (config.hardware.pulseaudio.enable && !config.hardware.pulseaudio.systemWide) {
      systemd.user.services.pulseaudio.environment.ALSA_CONFIG_UCM2 = "${pkgs.pine64-alsa-ucm}";
    })
    (lib.mkIf (config.hardware.pulseaudio.enable && config.hardware.pulseaudio.systemWide) {
      systemd.services.pulseaudio.environment.ALSA_CONFIG_UCM2 = "${pkgs.pine64-alsa-ucm}";
    })
  ];
}
