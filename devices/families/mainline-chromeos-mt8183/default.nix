{ config, lib, pkgs, ... }:

{
  imports = [
    ../mainline-chromeos
    ./sound.nix
  ];

  mobile.hardware = {
    soc = "mediatek-mt8183";
    ram = lib.mkDefault (1024 * 4);
  };

  mobile.boot.stage-1 = {
    kernel.package = pkgs.callPackage ./kernel {};
  };

  mobile.system.depthcharge.kpart = {
    dtbs = "${config.mobile.boot.stage-1.kernel.package}/dtbs/mediatek";
  };

  # Serial console on ttyS0, using a suzyqable or equivalent.
  mobile.boot.serialConsole = "ttyS0,115200n8";

  systemd.services."serial-getty@ttyS0" = {
    enable = true;
    wantedBy = [ "multi-user.target" ];
  };

  mobile.device.firmware = pkgs.callPackage ./firmware {};
  mobile.boot.stage-1.firmware = [
    config.mobile.device.firmware
  ];
  mobile.kernel.structuredConfig = [
    (helpers: with helpers; {
      # Undeclared dependency needed for some
      # hid-over-i2c trackpads (e.g. acer-juniper)
      HID_RMI = yes;
      SERIO = yes;
    })
  ];
}
