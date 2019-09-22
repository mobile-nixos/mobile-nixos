{ config, pkgs, ... }:

let
  device_config = config.mobile.device;
  stage-1 = config.mobile.boot.stage-1;
in
{
  system.build.initrd = pkgs.callPackage ../systems/initrd.nix { inherit device_config stage-1; };
}
