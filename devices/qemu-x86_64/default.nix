{ config, lib, pkgs, ... }:

let
  # This device description is a bit configurable through
  # mobile options...

  # Enabling the splash changes some settings.
  splash = config.mobile.boot.stage-1.splash.enable;

  kernel = pkgs.linuxPackages_5_4.kernel;
  device_info = {
   name = "QEMU (x86_64)";
  };

  modules = [
    # Disk images
    "ata_piix"
    "sd_mod"

    # Networking
    "e1000"

    # Keyboard
    "hid_generic"
    "pcips2" "atkbd" "i8042"

    # Mouse
    "mousedev"

    # Input within X11
    "uinput" "evdev"

    # USB
    "usbcore" "usbhid" "ehci_pci" "ehci_hcd"

    # x86 RTC needed by the stage 2 init script.
    "rtc_cmos"

    # Video
    "bochs_drm"
  ];
in
{
  mobile.device.name = "qemu-x86_64";
  mobile.device.info = device_info // {
    # TODO : make kernel part of options.
    inherit kernel;
    kernel_cmdline = lib.concatStringsSep " " ([
      "console=tty1"
      "console=ttyS0"
      "vt.global_cursor_default=0"
      "quiet"
    ]);
  };

  mobile.hardware = {
    soc = "generic-x86_64";

    # For the QEMU device, this *sets* the display size.
    screen = {
      width = 1080;
      height = 1920;
    };
    ram = 1024 * 2;
  };

  mobile.system.type = "qemu-startscript";
  mobile.boot.stage-1 = {
    kernel = {
      modular = true;
      inherit modules;
    };
  };
}
