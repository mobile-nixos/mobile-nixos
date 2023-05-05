{ lib, runCommand, mobile-nixos }:

let
  assets = runCommand "boot-splash-assets" {} ''
    mkdir -p $out
    ln -s /etc/logo.svg $out/logo.svg
  '';
in
mobile-nixos.mkLVGUIApp {
  name = "boot-splash.mrb";
  executablePath = "libexec/boot-splash.mrb";
  enableDebugInformation = true;
  src = lib.cleanSource ./.;
  rubyFiles = [
    "configuration.rb"
    "ui.rb"
    "main.rb"
  ];
  inherit assets;
  assetsPath = "boot-splash/assets";
}
