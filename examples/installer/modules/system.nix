{ lib, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    htop
    vim
    tmux
    cryptsetup
    e2fsprogs
  ];

  # Override stage-0 support for the installer.
  # It's not needed.
  mobile.quirks.supportsStage-0 = lib.mkForce false;

  # Force a lower brightness.
  # At some point the UI should allow configuring this.
  boot.postBootCommands = lib.mkOrder (-1) ''
    brightness=70
    echo "Setting brightness to $brightness"
    if [ -e /sys/class/backlight/backlight/brightness ]; then
      echo $(($(cat /sys/class/backlight/backlight/max_brightness) * brightness / 100)) > /sys/class/backlight/backlight/brightness
    elif [ -e /sys/class/leds/lcd-backlight/max_brightness ]; then
      echo $(($(cat /sys/class/leds/lcd-backlight/max_brightness)  * brightness / 100)) > /sys/class/leds/lcd-backlight/brightness
    elif [ -e /sys/class/leds/lcd-backlight/brightness ]; then
      # Assumes max brightness is 100... probably wrong, but good enough, eh.
      echo $brightness > /sys/class/leds/lcd-backlight/brightness
    fi
  '';

  networking.networkmanager.enable = true;
  networking.networkmanager.unmanaged = [ "rndis0" "usb0" ];
}
