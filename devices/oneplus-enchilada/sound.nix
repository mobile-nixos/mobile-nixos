{ config, lib, pkgs, ... }:

let
  ucm2 = "${pkgs.sdm845-alsa-ucm}/ucm2";
in {
  config = lib.mkMerge [
    {
      nixpkgs.overlays = [
        (self: super: {
          sdm845-alsa-ucm = self.callPackage (
            { fetchFromGitLab }:

            fetchFromGitLab {
              name = "sdm845-alsa-ucm";
              owner = "sdm845-mainline";
              repo = "alsa-ucm-conf";
              rev = "621c71fd5f5742c60d38766ebb2d1bd3b863a2a4"; # master
              sha256 = "sha256-CgAPg0UUAJUE1gD59l2GNDx3h9crAato6O/dDJpRwiY=";
            }
            ) {};
          })
        ];
    }
    (lib.mkIf config.sound.enable {
      environment.variables.ALSA_CONFIG_UCM2 = ucm2;
    })
    (lib.mkIf (config.hardware.pulseaudio.enable && !config.hardware.pulseaudio.systemWide) {
      systemd.user.services.pulseaudio.environment.ALSA_CONFIG_UCM2 = ucm2;
    })
    (lib.mkIf (config.hardware.pulseaudio.enable && config.hardware.pulseaudio.systemWide) {
      systemd.services.pulseaudio.environment.ALSA_CONFIG_UCM2 = ucm2;
    })
  ];
}
