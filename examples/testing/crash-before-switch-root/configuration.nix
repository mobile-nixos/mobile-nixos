{ config, lib, pkgs, ... }:

{
  mobile.boot.stage-1.tasks = [ ./crash.rb ];

  mobile.boot.stage-1.bootConfig = {
    log.level = lib.mkForce "INFO";
  };
}
