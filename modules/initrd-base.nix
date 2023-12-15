{ config, pkgs, ... }:

{
  config.mobile.boot.stage-1 = {
    extraUtils = [
      pkgs.hardshutdown
    ];
  };
}
