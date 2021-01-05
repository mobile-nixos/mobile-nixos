{ config, lib, pkgs, ... }:

let
  tdm-gui = "${pkgs.callPackage ./app {}}/libexec/app.mrb";
  internalStorageConfigured =
    config.mobile.boot.stage-1.bootConfig ? storage &&
    config.mobile.boot.stage-1.bootConfig.storage ? internal &&
    config.mobile.boot.stage-1.bootConfig.storage.internal != null
  ;
in
{
  mobile.boot.stage-1.tasks = [
    (# Slip an assertion here; nixos asserts only operate on `build.toplevel`.
    if !internalStorageConfigured
    then builtins.throw "mobile.boot.stage-1.bootConfig.storage.internal needs to be configured for ${config.mobile.device.name}."
    else ./gui-task.rb)
  ];

  # There is no mounting here.
  fileSystems = lib.mkForce {};

  mobile.boot.stage-1.usb = {
    enable = true;
    features = [ "mass_storage" ];
  };

  mobile.boot.stage-1.contents = with pkgs; [
    {
      object = tdm-gui;
      symlink = "/applets/tdm-gui.mrb";
    }
  ];

  system.build = {
    app-simulator = pkgs.callPackage ./app/simulator.nix {};
    rootfs = null;
  };

  mobile.boot.stage-1.networking.enable = true;
  mobile.boot.stage-1.ssh.enable = true;
}
