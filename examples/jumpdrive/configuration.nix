{ config, lib, pkgs, ... }:

{
  # There is no mounting here.
  fileSystems = lib.mkForce {};

  mobile.boot.stage-1.usb = {
    enable = true;
    features = [ "mass_storage" ];
  };

  system.build.rootfs = null;

  mobile.boot.stage-1.networking.enable = true;
  mobile.boot.stage-1.ssh.enable = true;
}
