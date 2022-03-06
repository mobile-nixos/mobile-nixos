{ config, lib, pkgs, ... }:
{
  # Shut down the modem in early boot
  mobile.quirks.u-boot.additionalCommands = ''
    # Properly shut off EG25 by pulling up PWRKEY.
    gpio set 35
    sleep 1
    gpio clear 35
  '';

  systemd.packages = [
    pkgs.eg25-manager
  ];

  systemd.targets.multi-user.wants = [ "eg25-manager.service" ];

  services.dbus.packages = [
    pkgs.eg25-manager
  ];
}
