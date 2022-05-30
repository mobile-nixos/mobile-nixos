{ config, lib, pkgs, ... }:

{
  mobile.device.name = "kobo-clara";
  mobile.device.identity = {
    name = "Clara HD";
    manufacturer = "Kobo";
  };

  mobile.hardware = {
    soc = "freescale-imx6sll";
    ram = 512;
    screen = {
      width = 1072; height = 1448;
    };
  };

  mobile.device.firmware = pkgs.callPackage ./firmware {};
  mobile.boot.stage-1 = {
    kernel.package = pkgs.callPackage ./kernel { };
    firmware = [
      config.mobile.device.firmware
    ];
  };

  mobile.usb.mode = "gadgetfs";
  mobile.usb.idVendor = "2237";
  mobile.usb.idProduct = "4228";
  mobile.usb.gadgetfs.functions = {
    rndis = "rndis.usb0";
    mass_storage = "mass_storage.0";
  };

  mobile.system.type = "u-boot";

  mobile.quirks.u-boot = {
    additionalCommands = ''
      led e60k02:white:on on
      setenv mmc_bootdev ''${devnum}
    '';
    # package = pkgs.callPackage ./u-boot {};
  };
}
