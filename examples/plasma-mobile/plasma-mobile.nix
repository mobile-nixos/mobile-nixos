#
# Minimum config used to enable Plasma Mobile.
#
{ config, lib, pkgs, ... }:

{
  mobile.beautification = {
    silentBoot = lib.mkDefault true;
    splash = lib.mkDefault true;
  };

  services.xserver = {
    enable = true;

    desktopManager.plasma5.mobile.enable = true;

    displayManager.autoLogin = {
      enable = true;
    };

    displayManager.defaultSession = "plasma-mobile";

    displayManager.lightdm = {
      enable = true;
      # Workaround for autologin only working at first launch.
      # A logout or session crashing will show the login screen otherwise.
      extraSeatDefaults = ''
        session-cleanup-script=${pkgs.procps}/bin/pkill -P1 -fx ${pkgs.lightdm}/sbin/lightdm
      '';
    };

    libinput.enable = true;
  };

  hardware.bluetooth.enable = true;
  services.pipewire.enable = lib.mkDefault true;
  hardware.pulseaudio.enable = lib.mkDefault false;
  networking.networkmanager.enable = true;
  networking.wireless.enable = false;
  powerManagement.enable = true;
}
