{ config, lib, pkgs, ... }:

{
  mobile.device.name = "qemu-x86_64";
  mobile.device.identity = {
   name = "(x86_64)";
   manufacturer = "QEMU";
  };

  mobile.device.info = {
    # TODO : make kernel part of options.
    kernel = pkgs.linuxPackages_5_4.kernel;
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

  boot.kernelParams = [
    "console=tty1"
    "console=ttyS0"
    "vt.global_cursor_default=0"
    "quiet"
  ];

  mobile.system.type = "qemu-startscript";

  mobile.boot.stage-1 = {
    kernel = {
      modular = true;
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
    };
  };
}
