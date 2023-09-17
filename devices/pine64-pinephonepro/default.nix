{ config, lib, pkgs, ... }:

{
  imports = [
    ./kernel-config.nix
  ];

  mobile.device.name = "pine64-pinephonepro";
  mobile.device.identity = {
    name = "Pinephone Pro";
    manufacturer = "Pine64";
  };
  mobile.device.supportLevel = "supported";

  mobile.hardware = {
    soc = "rockchip-rk3399s";
    ram = 1024 * 4;
    screen = {
      width = 720; height = 1440;
    };
  };

  mobile.boot.stage-1 = {
    kernel.package = pkgs.callPackage ./kernel { };
  };

  boot.kernelParams = [
    "earlycon=uart8250,mmio32,0xff1a0000"
  ];

  # Serial console on ttyS2, using the serial headphone adapter.
  mobile.boot.serialConsole = "ttyS2,115200";

  mobile.system.type = "u-boot";

  mobile.usb.mode = "gadgetfs";


  # It seems Pine64 does not have an idVendor...
  mobile.usb.idVendor = "1209";  # http://pid.codes/1209/
  mobile.usb.idProduct = "0069"; # "common tasks, such as testing, generic USB-CDC devices, etc."

  # Mainline gadgetfs functions
  mobile.usb.gadgetfs.functions = {
    rndis = "rndis.usb0";
    mass_storage = "mass_storage.0";
    adb = "ffs.adb";
  };

  mobile.boot.stage-1.bootConfig = {
    # Used by target-disk-mode to share the internal drive
    storage.internal = "/dev/disk/by-path/platform-fe330000.mmc";
  };

  mobile.device.firmware = pkgs.callPackage ./firmware {};
  mobile.boot.stage-1.firmware = [
    config.mobile.device.firmware
  ];
  hardware.firmware = [
    config.mobile.device.firmware
  ];

  # Modem service
  services.eg25-manager.enable = lib.mkDefault true;

  # Alsa UCM profiles
  mobile.quirks.audio.alsa-ucm-meld = true;
  environment.systemPackages = [ pkgs.mobile-nixos.pine64-alsa-ucm ];

  mobile.boot.stage-1.tasks = [ ./usb_role_switch_task.rb ];

  mobile.documentation.hydraOutputs = [
    ["installer.@device@" "Installer image"]
  ];
}
