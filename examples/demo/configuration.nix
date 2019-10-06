{ config, lib, pkgs, ... }:

let
  inherit (lib) mkForce;

  # Why copy them all?
  # Because otherwise the wallpaper picker will default to /nix/store as a path
  # and this could get messy with the amazing amount of files there are in there.
  # Why copy only pngs?
  # Rendering of `svg` is hard! Not that it's costly in cpu time, but that the
  # rendering might not be as expected depending on what renders it.
  # The SVGs in that directory are used as an authoring format files, not files
  # to be used as they are. They need to be pre-rendered.
  wallpapers = pkgs.runCommandNoCC "wallpapers" {} ''
    mkdir -p $out/
    cp ${../../artwork/wallpapers}/*.png $out/
  '';

  # TODO: DPI/size settings, so that a DPI can be derived from the device info.
  xfce4-defaults = pkgs.runCommandNoCC "xfce4-defaults" {} ''
    cp -r ${./xdg/xfce4} $out
    wallpaper="${wallpapers}/mobile-nixos-19.09.png"
    substituteInPlace $out/xfconf/xfce-perchannel-xml/xfce4-desktop.xml \
      --subst-var wallpaper
  '';
in
  {
    imports = [
      ../../profiles/installer.nix
    ];
    disabledModules = [
      <nixpkgs/nixos/modules/installer/cd-dvd/iso-image.nix>
      <nixpkgs/nixos/modules/installer/cd-dvd/installation-cd-base.nix>
    ];

  config = lib.mkMerge [
    {

      services.xserver = {
        enable = true;

        libinput.enable = true;
        videoDrivers = [ "fbdev" ];

        # xfce has been chosen mainly because it is light, and quick to start.
        # FIXME: Find a better demo environment.
        desktopManager.xfce.enable = true;

        # Automatically login as nixos.
        displayManager.lightdm = {
          enable = true;
          autoLogin = {
            enable = true;
            user = "nixos";
          };
        };

      };

      powerManagement.enable = true;
      hardware.pulseaudio.enable = true;

      environment.systemPackages = with pkgs; [
        firefox
        sgtpuzzles
        hard-reboot
        hard-shutdown

        adapta-gtk-theme
      ];

      fonts.fonts = with pkgs; [
        aileron
      ];

      environment.etc."xdg/xfce4" = {
        source = xfce4-defaults;
      };

      # Hacky way to setup an initial brightness
      # TODO: better factor this out...
      mobile.boot.stage-1.initFramebuffer = ''
        brightness=10
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

      # Puts some icons on the desktop.
      system.activationScripts.fillDesktop = let
        minesDesktopFile = pkgs.writeScript "mines.desktop" ''
          [Desktop Entry]
          Version=1.0
          Type=Application
          Name=Mines
          Exec=${pkgs.sgtpuzzles}/bin/sgt-puzzle-mines
        '';

        homeDir = "/home/nixos/";
        desktopDir = homeDir + "Desktop/";

      in ''
        mkdir -p ${desktopDir}
        chown nixos ${homeDir} ${desktopDir}

        ln -sfT ${minesDesktopFile} ${desktopDir + "mines.desktop"}
      '';

      # FIXME : Stop relying on initrd for `ssh` via USB.
      networking.networkmanager.enable = true;
      networking.networkmanager.unmanaged = [ "rndis0" "usb0" ];

      # Setup USB gadget networking in initrd...
      mobile.boot.stage-1.networking.enable = true;
      #mobile.boot.stage-1.ssh.enable = true;

      # Start SSH by default...
      systemd.services.sshd.wantedBy = lib.mkOverride 10 [ "multi-user.target" ];
      services.openssh.permitRootLogin = lib.mkForce "yes";

      # Forcibly set a password on users...
      # FIXME: highly insecure!
      # FIXME: Figure out why this breaks...
      #services.openssh.extraConfig = "PermitEmptyPasswords yes";
      users.users.nixos.password = "nixos";
      users.users.root.password = "nixos";

      # Okay, systemd-udev-settle times out... no idea why yet...
      # Though, it seems fine to simply disable it.
      # FIXME : figure out why systemd-udev-settle doesn't work.
      systemd.services.systemd-udev-settle.enable = false;
    }
  ];
}
