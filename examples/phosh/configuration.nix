{ config, lib, pkgs, ... }:

let
  inherit (lib) mkForce;
  system_type = config.mobile.system.type;

  defaultUserName = "alice";
in
{
  config = {
    users.users."${defaultUserName}" = {
      isNormalUser = true;
      password = "1234";
      extraGroups = [
        "dialout"
        "feedbackd"
        "networkmanager"
        "video"
      ];
    };
    
    services.xserver.desktopManager.phosh = {
      enable = true;
      user = defaultUserName;
      group = "users";
    };

    programs.calls.enable = true;
    hardware.sensor.iio.enable = true;

    environment.systemPackages = [
      pkgs.chatty
      pkgs.kgx
      pkgs.megapixels
    ];

  };
}
