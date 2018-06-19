{ config, lib, pkgs, ... }:

with import ../../modules/initrd-order.nix;
let
  kernel = pkgs.linuxPackages_4_16.kernel;
  device_info = (lib.importJSON ../postmarketOS-devices.json).qemu-amd64;

  MODES = {
      "800x600x16" = { vga =   "788"; width =  800; height =  600; depth = 16; };
     "1024x786x16" = { vga =   "791"; width = 1024; height =  768; depth = 16; };
     "1024x786x32" = { vga = "0x344"; width = 1024; height =  768; depth = 32; };
    "1280x1024x16" = { vga =   "794"; width = 1280; height = 1024; depth = 16; };
     "1280x720x16" = { vga = "0x38d"; width = 1280; height =  720; depth = 16; };
     "1280x720x24" = { vga = "0x38e"; width = 1280; height =  720; depth = 24; };
     "1280x720x32" = { vga = "0x38f"; width = 1280; height =  720; depth = 32; };
    "1920x1080x16" = { vga = "0x390"; width = 1920; height = 1080; depth = 16; };
    "1920x1080x24" = { vga = "0x391"; width = 1920; height = 1080; depth = 24; };
    "1920x1080x32" = { vga = "0x392"; width = 1920; height = 1080; depth = 32; };
  };

  MODE = MODES."1280x720x32";
in
{
  mobile.device.name = "qemu-x86_64";
  mobile.device.info = device_info // {
    # TODO : make kernel part of options.
    inherit kernel;
    kernel_cmdline = device_info.kernel_cmdline + " vga=${MODE.vga}";
  };
  mobile.hardware = {
    soc = "generic-x86_64";
    screen = {
      inherit (MODE) height width;
    };
    ram = 512;
  };
  mobile.system.type = "kernel-initrd";
  mobile.boot.stage-1 = {
    # Comment the next two if you want to play around with splash.
    redirect-log.targets = [ "/dev/tty0" "/dev/kmsg" ];
    splash.enable = false;
    init = (lib.mkOrder BEFORE_READY_INIT ''
      echo "cmdline:"
      cat /proc/cmdline
      echo "Hi there from /init!"
    '');
  };
}
