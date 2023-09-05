{ config, lib, pkgs, ... }:

{
  mobile.quirks.audio.alsa-ucm-meld = true;
  environment.systemPackages = [
    pkgs.google-kukui-alsa-ucm
  ];

  nixpkgs.overlays = [
    (self: super: {
      google-kukui-alsa-ucm = self.callPackage (
        { runCommand, fetchzip }:
        let
          rev = "fac4d7e17871a8e7ec1c39f58257389e9bf62f06";
        in
        runCommand "google-kukui-alsa-ucm" {
          # From https://gitlab.com/postmarketOS/pmaports/-/tree/master/temp/alsa-ucm-conf-google-kukui
          src = fetchzip {
            url = "https://gitlab.com/postmarketOS/pmaports/-/archive/${rev}/pmaports-${rev}.tar.bz2?path=temp/alsa-ucm-conf-google-kukui";
            extension = "tar.bz2";
            sha256 = "sha256-fBdBE38RYVb0dhYbMhN8jRbRB7z/PqpWPx2QBtFhp/A=";
          };
        } ''
          src="$src/temp/alsa-ucm-conf-google-kukui"
          install -Dm644 $src/mt8183_da7219_HiFi.conf \
            $out/share/alsa/ucm2/conf.d/mt8183_da7219_r/HiFi.conf
          install -Dm644 $src/mt8183_da7219_rt1015p.conf \
            $out/share/alsa/ucm2/conf.d/mt8183_da7219_r/mt8183_da7219_rt1015p.conf

          install -Dm644 $src/mt8183_mt6358_HiFi.conf \
            $out/share/alsa/ucm2/conf.d/mt8183_mt6358_t/HiFi.conf
          install -Dm644 $src/mt8183_mt6358_ts3a227_max98357.conf \
            $out/share/alsa/ucm2/conf.d/mt8183_mt6358_t/mt8183_mt6358_ts3a227_max98357.conf
        ''
      ) {};
    })
  ];
}
