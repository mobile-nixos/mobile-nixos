{ config, lib, pkgs, ... }:

{
  mobile.device.name = "pine64-pine-a64-lts";
  mobile.device.info = {
    format_version = "0";
    name = "PINE A64-LTS";
    manufacturer = "PINE64";
    date = "";
    dtb = "";
    modules_initfs = "";
    arch = "aarch64";

    keyboard = false;
    external_storage = true;

    # Hmmm...
    screen_width = "1920";
    screen_height = "1080";

    flash_method = "fastboot";

    kernel_cmdline = "console=tty0 console=ttyS0,115200 no_console_suspend earlycon=uart,mmio32,0x01c28000 panic=10 consoleblank=0 loglevel=1";

    # Hmm, this smells fishy, android bootimg in an allwinner device?
    # Read on!
    generate_bootimg = true;

    # This is the usual for allwinner.
    flash_offset_base    = "0x40000000";
    flash_offset_kernel  = "0x00080000";
    flash_offset_ramdisk = "0x0fe00000";
    # The next two don't really matter I think
    flash_offset_second  = "0x00000000";
    flash_offset_tags    = "0x00000100";
    flash_pagesize = "2048";

	# What?? Allwinner != Qualcomm!!
    # No, but this is a *testing* target, which has a u-boot modified to act
    # like a qualcomm board, because (1) it is more convenient as a dev
    # platform than a phone you can irreparably brick (2) the current
    # nixos-mobile build system will not output a boot.img with a device tree
    # in the new android format and (3) the qualcomm format is really simple to
    # implement as a quick hack.
    #
    # So uh, this may be moved, in the future, into another "device" made for
    # testing, or into some other semantics allowing overriding devices.
    bootimg_qcdt = true;

    # TODO : make kernel part of options.
    kernel = pkgs.callPackage ./kernel { kernelPatches = pkgs.defaultKernelPatches; };
  };
  mobile.hardware = {
    soc = "allwinner-r18";
    ram = 1024 * 2;
    screen = {
	  # Hmmm...
      width = 1920; height = 1080;
    };
  };

  mobile.system.type = "android-bootimg";
}
