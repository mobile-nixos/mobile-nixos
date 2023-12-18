{ config, lib, pkgs, ... }:

let
  defaultUserName = "alice";
in
{
  imports = [
    ./phosh.nix
    ../common-configuration.nix
  ];

  config = {
    users.users."${defaultUserName}" = {
      isNormalUser = true;
      password = "1234";
      extraGroups = [
        "dialout"
        "feedbackd"
        "networkmanager"
        "video"
        "wheel"
      ];
    };
    
    services.xserver.desktopManager.phosh = {
      user = defaultUserName;
    };
  };
}
