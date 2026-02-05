{
  config,
  lib,
  options,
  pkgs,
  ...
}: {

  options = {
    mobile.phosh = {
      enable = lib.mkEnableOption "Phosh mobile desktop environment";

      user = lib.mkOption {
        type = lib.types.str;
        description = "The user for which to configure the Phosh session";
      };

      installDefaultApps = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Whether to install default mobile applications";
      };
    };
  };

  config = lib.mkIf config.mobile.phosh.enable {
    # Assertion to ensure user is set.
    assertions = [
      {
        assertion = config.mobile.phosh.user != "";
        message = ''
          `mobile.phosh.user` not set.
          When enabling the phosh configuration, you need to set `mobile.phosh.user` to the username of the session user.
        '';
      }
    ];

    mobile.beautification = {
      silentBoot = lib.mkDefault true;
      splash = lib.mkDefault true;
    };

    # Enable Phosh desktop environment.
    services.xserver = {
      enable = true;
      desktopManager.phosh = {
        enable = true;
        user = config.mobile.phosh.user;
        group = "users";
      };
    };

    # Essential services for mobile environment
    hardware.sensor.iio.enable = lib.mkDefault true;
    hardware.bluetooth.enable = lib.mkDefault true;
    services.pipewire.enable = lib.mkDefault true;
    services.pulseaudio.enable = lib.mkDefault false;
    networking.networkmanager.enable = lib.mkDefault true;
    networking.wireless.enable = lib.mkDefault false;
    powerManagement.enable = lib.mkDefault true;
    services.libinput.enable = lib.mkDefault true;
    programs.calls.enable = lib.mkDefault true;

    # Install essential mobile packages.
    environment.systemPackages = lib.mkIf config.mobile.phosh.installDefaultApps (with pkgs; [
      phosh-mobile-settings
      portfolio-filemanager
      confy
      cozy
      dialect
      dino
      foliate
      authenticator
      gnome-podcasts
      iotas
      passes
      #picplanner
      plattenalbum
      railway
      satellite
      saldo
      shortwave
      tuba
      wike
      luanti
      syncthing
      # Essential mobile applications
      epiphany            # Web browser
      gnome-console       # Terminal
      megapixels          # Camera
    ]);
  };
}