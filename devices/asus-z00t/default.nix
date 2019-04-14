{ config, lib, pkgs, ... }:

{
  mobile.device.name = "asus-z00t";
  mobile.device.info = (lib.importJSON ../postmarketOS-devices.json).asus-z00t // rec {
    # TODO : make kernel part of options.
    kernel = pkgs.callPackage ./kernel { kernelPatches = pkgs.defaultKernelPatches; };
    dtb = "${kernel}/dtbs/asus-z00t.img";
  };
  mobile.hardware = {
    # This could also be pre-built option types?
    soc = "qualcomm-msm8939";
    # 3GB for the specific revision supported.
    # When this will be actually used, this may be dropped to 2, and/or
    # document all ram types as a list and work with min/max of those.
    ram = 1024 * 3;
    screen = {
      width = 1080; height = 1920;
    };
  };

  mobile.system.type = "android-bootimg";
}
