{ config, pkgs, ... }:

let
  cfg = config.mobile.boot.stage-1;
in
{
  config.mobile.boot.stage-1 = {
    extraUtils = [
      pkgs.hardshutdown
    ];
  };
}
