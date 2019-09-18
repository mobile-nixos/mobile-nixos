{ config, lib, pkgs, ... }:

{
  mobile.device.name = "asus-dumo";
  mobile.device.info = rec {
    format_version = "0";
    name = "ASUS Chromebook Tablet CT100PA";
    manufacturer = "ASUS";
    arch = "aarch64";
    keyboard = false;
    external_storage = true;
    # Serial console on ttyS2, using a suzyqable or equivalent.
    kernel_cmdline = "console=ttyS2,115200n8 earlyprintk=ttyS2,115200n8 loglevel=8";
    # TODO : move kernel outside of the basic device details
    kernel = pkgs.callPackage ./kernel {};
    # This could be further pared down to only the required dtb files.
    dtbs = "${kernel}/dtbs/rockchip";
  };
  mobile.hardware = {
    soc = "rockchip-op1";
    ram = 1024 * 4;
    screen = {
      width = 1536; height = 2048;
    };
  };

  mobile.system.type = "depthcharge";
}
