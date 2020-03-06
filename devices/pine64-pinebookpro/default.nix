{ config, lib, pkgs, ... }:

{
  mobile.device.name = "pine64-pinebookpro";
  mobile.device.info = rec {
    format_version = "0";
    name = "Pine64 PINEBOOK Pro";
    manufacturer = "Pine64";
    arch = "aarch64";
    keyboard = true;
    external_storage = true;

    # Serial console on ttyS2, using the dedicated cable.
    kernel_cmdline = lib.concatStringsSep " " [
      "cma=32M"
      "console=ttyS2,1500000n8"
      "earlycon=uart8250,mmio32,0xff1a0000"
      "earlyprintk"

      "quiet"
      "vt.global_cursor_default=0"
    ];
    # TODO : move kernel outside of the basic device details
    kernel = (pkgs.callPackage ./kernel {
      kernelPatches = with pkgs; [
        kernelPatches.bridge_stp_helper
        #kernelPatches.export_kernel_fpu_functions
      ];
    }).overrideAttrs({passthru ? {}, ...}: {
      passthru = passthru // {
        file = "Image";
      };
    });
  };
  mobile.hardware = {
    soc = "rockchip-rk3399";
    ram = 1024 * 4;
    screen = {
      width = 1920; height = 1080;
    };
  };

  mobile.system.type = "u-boot";
  mobile.quirks.u-boot.package = pkgs.callPackage ./u-boot {};
}
