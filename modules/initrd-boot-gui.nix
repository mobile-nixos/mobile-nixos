{ config, lib, pkgs, ... }:

let
  boot-gui = ../boot/gui;
  boot-selection = pkgs.runCommand "boot-selection.mrb" {} ''
    ${pkgs.buildPackages.mruby}/bin/mrbc -o $out ${boot-gui}/lib/*.rb ${boot-gui}/main.rb
  '';
in
{
  mobile.boot.stage-1.contents = with pkgs; [
    {
      object = (builtins.path { path = ../artwork/logo/logo.white.svg; });
      symlink = "/etc/logo.svg";
    }
    {
      object = boot-selection;
      symlink = "/applets/boot-selection.mrb";
    }
  ];
}
