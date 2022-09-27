{ lib, runCommand, mobile-nixos }:

let
  assets = runCommand "boot-splash-assets" {} ''
    mkdir -p $out
    cp ${../../artwork/logo/logo.white.svg} $out/logo.svg
  '';
in
mobile-nixos.mkLVGUIApp {
  name = "boot-splash.mrb";
  executablePath = "libexec/boot-splash.mrb";
  src = lib.cleanSource ./.;
  rubyFiles = [
    "ui.rb"
    "main.rb"
  ];
  inherit assets;
  assetsPath = "boot-splash/assets";
}
