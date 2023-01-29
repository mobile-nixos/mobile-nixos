{ lib, ... }:
{
  # Shut down the modem in early boot
  mobile.quirks.u-boot.additionalCommands = ''
    # Properly shut off EG25 by pulling up PWRKEY.
    gpio set 35
    sleep 1
    gpio clear 35
  '';

  services.eg25-manager.enable = lib.mkDefault true;
}
