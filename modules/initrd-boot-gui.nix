{ config, lib, pkgs, ... }:

let
  key-held = pkgs.runCommand "key-held.mrb" {} ''
    ${pkgs.buildPackages.mruby}/bin/mrbc -o $out ${../boot/applets}/key-held.rb
  '';
  boot-error = pkgs.runCommand "boot-error.mrb" {} ''
    ${pkgs.buildPackages.mruby}/bin/mrbc -o $out ${../boot/recovery-menu}/lib/*.rb ${../boot/error}/main.rb
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
      object = pkgs.mobile-nixos.stage-1.boot-splash;
      symlink = "/applets/boot-splash.mrb";
    }
    {
      object = pkgs.mobile-nixos.stage-1.boot-recovery-menu;
      symlink = "/applets/boot-selection.mrb";
    }
    {
      object = key-held;
      symlink = "/applets/key-held.mrb";
    }
  ];
  mobile.boot.stage-1.extraUtils = with pkgs; [
    # Used for `key-held.mrb`.
    { package = evtest; }
  ];
}
