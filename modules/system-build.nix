{ config, lib, pkgs, ... }:

let
  inherit (lib) mkIf;

  deviceName = config.mobile.device.name;
in
{
  config = mkIf (!config.mobile.rootfs.shared.enabled) {
    system.extraSystemBuilderCmds = ''
      echo ":: Adding Mobile NixOS information to the build..."
      (
        PS4=" $ "; set -x
        mkdir -p $out/mobile-nixos
        cd $out/mobile-nixos
        echo "${deviceName}" > device-name
      )
    '';
  };
}
