#
# This file represents safe opinionated defaults for a basic Phosh system.
#
# NOTE: this file and any it imports **have** to be safe to import from
#       an end-user's config.
#
{ pkgs, ... }:

{
  services.xserver.desktopManager.phosh = {
    enable = true;
    group = "users";
  };

  programs.calls.enable = true;

  environment.systemPackages = with pkgs; [
    chatty              # IM and SMS
    epiphany            # Web browser
    kgx                 # Terminal
    megapixels          # Camera
  ];

  hardware.sensor.iio.enable = true;
}
