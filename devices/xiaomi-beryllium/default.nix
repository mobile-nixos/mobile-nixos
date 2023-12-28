{ config, lib, pkgs, ... }:

{
  imports = [
    ../families/sdm845-mainline
  ];

  mobile.device.name = "xiaomi-beryllium-tianma";
  mobile.device.identity = {
    name = "Pocophone F1 / POCO F1";
    manufacturer = "Xiaomi";
  };
  mobile.device.supportLevel = "supported";

  mobile.hardware = {
    ram = 1024 * 6;
    screen = {
      width = 1080; height = 2246;
    };
  };

  mobile.device.firmware = pkgs.callPackage ./firmware {};

  mobile.system.android = {
    device_name = "beryllium";
    ab_partitions = false;
    bootimg.flash.offset_second = lib.mkForce "0x00008000"; # maybe not even used
  };

  mobile.boot.boot-control.enable = false;
}
