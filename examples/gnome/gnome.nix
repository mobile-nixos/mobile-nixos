#
# This file represents safe opinionated defaults for a basic GNOME mobile system.
#
# NOTE: this file and any it imports **have** to be safe to import from
#       an end-user's config.
#
{ config, lib, pkgs, options, ... }:

{
  mobile.beautification = {
   silentBoot = lib.mkDefault true;
   splash = lib.mkDefault true;
  };

  nixpkgs.overlays = [
    (import ./overlay)
  ];

  services.xserver.enable = true;
  services.xserver.desktopManager.gnome = {
    enable = true;
    extraGSettingsOverrides = ''
      [org.gnome.mutter.dynamic-workspaces]
      enabled=true
    '';
    extraGSettingsOverridePackages = [ pkgs.gnome.mutter ];
  };
  services.xserver.displayManager.gdm.enable = true;

  programs.calls.enable = true;

  environment.systemPackages = with pkgs; [
    chatty              # IM and SMS
    epiphany            # Web browser
    gnome-console       # Terminal
    megapixels          # Camera
  ];

  hardware.sensor.iio.enable = true;
}
