{ config, lib, pkgs, ... }:

let
  inherit (lib) mkIf optionalString;

  deviceName = config.mobile.device.name;

  dtbMapping = pkgs.runCommand "dtb-mapping.json" {} ''
    (
      PS4=" $ "; set -x
      ${pkgs.buildPackages.mobile-nixos.map-dtbs}/bin/map-dtbs $(find ${config.hardware.deviceTree.package} -name '*.dtb' | sort) > $out
    )
  '';
in
{
  config = mkIf (config.mobile.enable && !config.mobile.rootfs.shared.enabled) {
    system.systemBuilderCommands = ''
      echo ":: Adding Mobile NixOS information to the build..."
      (
        PS4=" $ "; set -x
        mkdir -p $out/mobile-nixos
        cd $out/mobile-nixos
        echo "${deviceName}" > device-name
        ${optionalString (config.hardware.deviceTree.package != null) ''
          ln -s ${dtbMapping} dtb-mapping.json
        ''}
      )
    '';
  };
}
