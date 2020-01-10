{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.mobile.boot.stage-1;
in
{
  config.mobile.boot.stage-1 = {
    extraUtils = with pkgs; [
      hardshutdown
    ];
  };
}
