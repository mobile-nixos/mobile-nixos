{ config, lib, pkgs, ... }:

{
  mobile.quirks.audio.alsa-ucm-meld = true;
  environment.systemPackages = [
    pkgs.google-trogdor-alsa-ucm
  ];

  nixpkgs.overlays = [
    (self: super: {
      google-trogdor-alsa-ucm = self.callPackage (
        { runCommand, fetchgit }:
        let
          rev = "fac4d7e17871a8e7ec1c39f58257389e9bf62f06";
        in
        runCommand "google-trogdor-alsa-ucm" {
          src = fetchgit {
            url = "https://chromium.googlesource.com/chromiumos/overlays/board-overlays";
            rev = "e8eef57902e62ebe421751d31445d57ee90eda1b";
            hash = "sha256:0iq4mafs6fhlxnb7fhia6p4rbk2kdv0r5417db3fzmirh3lj0cd0";
          };
        } ''
          src="$src/overlay-strongbad/chromeos-base/chromeos-bsp-strongbad/files/wormdingler/audio/ucm-config/"
          install -Dm644 $src/sc7180-rt5682-max98357a-1mic/HiFi.conf \
            $out/share/alsa/ucm2/conf.d/sc7180-rt5682-max98357a-1mic/HiFi.conf
          install -Dm644 $src/sc7180-rt5682-max98357a-1mic/sc7180-rt5682-max98357a-1mic.conf \
            $out/share/alsa/ucm2/conf.d/sc7180-rt5682-max98357a-1mic/sc7180-rt5682-max98357a-1mic.conf

          install -Dm644 $src/sc7180-rt5682s-max98357a-1mic/HiFi.conf \
            $out/share/alsa/ucm2/conf.d/sc7180-rt5682s-max98357a-1mic/HiFi.conf
          install -Dm644 $src/sc7180-rt5682s-max98357a-1mic/sc7180-rt5682s-max98357a-1mic.conf \
            $out/share/alsa/ucm2/conf.d/sc7180-rt5682s-max98357a-1mic/sc7180-rt5682s-max98357a-1mic.conf
        ''
      ) {};
    })
  ];
}
