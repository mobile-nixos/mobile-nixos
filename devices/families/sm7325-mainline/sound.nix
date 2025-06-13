{ pkgs, ... }:

{
  nixpkgs.overlays = [
    (self: super: {
      sc7280-alsa-ucm = self.callPackage (
        { runCommand, fetchFromGitHub }:

        runCommand "sc7280-alsa-ucm" {
          src = fetchFromGitHub {
            owner = "sc7280-mainline";
            repo = "alsa-ucm-conf";
            rev = "e2f6767c294c458a2b02214d5c74460b1c50eed8";
            sha256 = "sha256-FYy9/18QdRgMWzNyoCG3P7x3gU/DnnBQGlPdQHks53Q=";
          };
        } ''
          mkdir -p $out/share/
          ln -s $src $out/share/alsa
        ''
      ) {};
    })
  ];

  services.udev.extraRules = ''
    SUBSYSTEM=="sound", KERNEL=="card0", ATTR{id}=="NP1", ENV{ID_ID}="NP1"
  '';

  # Alsa UCM profiles
  mobile.quirks.audio.alsa-ucm-meld = true;
  environment.systemPackages = [
    pkgs.sc7280-alsa-ucm
  ];
}
