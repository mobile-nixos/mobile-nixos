{ config, lib, ... }:

let
  inherit (lib)
    optionalString
  ;
  inherit (config.mobile)
    system
  ;
in
{
  # Pins pre-built artifacts within the system closure that are going to be
  # used by the installer.
  system.extraSystemBuilderCmds = ''
    echo ":: Adding pre-built boot files to closure..."
    (
      PS4=" $ "; set -x
      mkdir -p $out/mobile-nixos-installer
      cd $out/mobile-nixos-installer
      ln -s ${config.mobile.boot.stage-1.kernel.package} kernel
      ${optionalString (system.type == "depthcharge") ''
        ln -s ${config.mobile.outputs.depthcharge.kpart} kpart
      ''}
      ${optionalString (system.type == "u-boot") ''
        ln -s ${config.mobile.outputs.u-boot.boot-partition} boot-partition
      ''}
    )
  '';
}
