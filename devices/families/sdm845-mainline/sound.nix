{ config, lib, pkgs, ... }:

{
  nixpkgs.overlays = [
    (self: super: {
      sdm845-alsa-ucm = self.callPackage (
        { stdenv, fetchFromGitLab }:

        stdenv.mkDerivation {
          name = "sdm845-alsa-ucm";
          src = fetchFromGitLab {
            name = "sdm845-alsa-ucm";
            owner = "sdm845-mainline";
            repo = "alsa-ucm-conf";
            rev = "9ed12836b269764c4a853411d38ccb6abb70b383"; # master
            hash = "sha256-QvGZGLEmqE+sZpd15fHb+9+MmoD5zoGT+pYqyWZLdkM=";
          };
          patches = [ ./sound-oneplus-enchilada.patch ];
          installPhase = ''
            mkdir -p $out/share/
            cp -r . $out/share/alsa
          '';
        }
      ) {};
    })
  ];

  # Alsa UCM profiles
  mobile.quirks.audio.alsa-ucm-meld = true;
  environment.systemPackages = [
    pkgs.sdm845-alsa-ucm
  ];
}
