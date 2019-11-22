{ config, lib, pkgs, ... }:

{
  mobile.device.name = "pine64-dont-be-evil";
  mobile.device.info = rec {
    name = "PinePhone Don't be evil development kit";
    # TODO : make kernel part of options.
    kernel = pkgs.callPackage ./kernel { kernelPatches = pkgs.defaultKernelPatches; };

    format_version = "0";
    manufacturer = "PINE64";
    codename = "pine64-dont-be-evil";
    date = "";
    dtb = "${kernel}/sun50i-a64-dontbeevil.dtb";
    modules_initfs = "";
    arch = "aarch64";
    keyboard = false;
    external_storage = true;
    screen_width = "720";
    screen_height = "1440";

    flash_method = "fastboot";


    kernel_cmdline = "console=tty0 console=ttyS0,115200 no_console_suspend earlycon=uart,mmio32,0x01c28000 panic=10 consoleblank=0";
    # Hmm, this smells fishy, android bootimg in an allwinner device?
    # Read on!
    generate_bootimg = true;
    bootimg_qcdt = true; # FIXME: Use a more appropriate option for appending the dtb to the boot.img.

    # This is the usual for allwinner.
    flash_offset_base    = "0x40000000";
    flash_offset_kernel  = "0x00080000";
    flash_offset_ramdisk = "0x0fe00000";
    # The next two don't really matter I think
    flash_offset_second  = "0x00000000";
    flash_offset_tags    = "0x00000100";
    flash_pagesize = "2048";

  };

  mobile.hardware = {
    soc = "allwinner-r18";
    ram = 1024 * 2;
    screen = {
      width = 720; height = 1440;
    };
  };

  # Not really, but we're making it act like one.
  mobile.system.type = "android";
}
