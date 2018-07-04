{ config, lib, pkgs, ... }:

{
  mobile.device.name = "asus-flo";
  mobile.device.info = (lib.importJSON ../postmarketOS-devices.json).asus-flo // {
    # TODO : make kernel part of options.
    kernel = pkgs.callPackage ./kernel { kernelPatches = pkgs.defaultKernelPatches; };
  };
  mobile.hardware = {
    soc = "qualcomm-apq8064-1aa";
    ram = 1024 * 2;
    screen = {
      width = 1200; height = 1920;
    };
  };

  mobile.system.type = "android-bootimg";
}
