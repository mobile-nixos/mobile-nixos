{ config, lib, pkgs, ... }:

let
  key-held = pkgs.runCommand "key-held.mrb" {} ''
    ${pkgs.buildPackages.mruby}/bin/mrbc -o $out ${../boot/applets}/key-held.rb
  '';
  boot-gui = ../boot/gui;
  boot-selection = pkgs.runCommand "boot-selection.mrb" {} ''
    ${pkgs.buildPackages.mruby}/bin/mrbc -o $out ${boot-gui}/lib/*.rb ${boot-gui}/main.rb
  '';
  boot-splash = pkgs.runCommand "boot-splash.mrb" {} ''
    ${pkgs.buildPackages.mruby}/bin/mrbc -o $out ${../boot/gui}/lib/*.rb ${../boot/splash}/main.rb
  '';
  boot-error = pkgs.runCommand "boot-error.mrb" {} ''
    ${pkgs.buildPackages.mruby}/bin/mrbc -o $out ${../boot/gui}/lib/*.rb ${../boot/error}/main.rb
  '';
in
{
  mobile.boot.stage-1.contents = with pkgs; [
    {
      object = (builtins.path { path = ../artwork/logo/logo.white.svg; });
      symlink = "/etc/logo.svg";
    }
    {
      object = boot-error;
      symlink = "/applets/boot-error.mrb";
    }
    {
      object = boot-splash;
      symlink = "/applets/boot-splash.mrb";
    }
    {
      object = boot-selection;
      symlink = "/applets/boot-selection.mrb";
    }
    {
      object = key-held;
      symlink = "/applets/key-held.mrb";
    }
  ];
  mobile.boot.stage-1.extraUtils = with pkgs; [
    # Used for `key-held.mrb`.
    { package = pkgsStatic.evtest; }
  ];
}
