{ config, lib, pkgs, ... }:

with lib;
with import ./initrd-order.nix;

let
  cfg = config.mobile.boot.stage-1.splash;
in
{
  config.mobile.boot.stage-1 = lib.mkIf cfg.enable {
    init = lib.mkOrder READY_INIT ''
      show_splash splash
    '';
    extraUtils = [
      pkgs.fbv
    ];
    contents = [
      { object = ../temp-splash.png; symlink = "/splash.png"; }
    ];
  };
}
