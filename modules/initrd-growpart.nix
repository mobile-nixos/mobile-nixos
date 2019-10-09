# This builds a rootfs image (ext4) from the current configuration.
{ config, lib, pkgs, ... }:

let
  inherit (config.boot) growPartition;
  inherit (lib) mkIf mkOrder optionalString;
  inherit (import ./initrd-order.nix) BEFORE_SWITCH_ROOT_INIT;
  root = config.fileSystems."/";
in
{

  mobile.boot.stage-1.init = mkIf growPartition (mkOrder BEFORE_SWITCH_ROOT_INIT ''
    (
      ${optionalString growPartition ''
        ${optionalString (root.fsType == "ext4") ''
          e2fsck -fp ${root.device}
          resize2fs -f ${root.device}
        ''}
      ''}
    )
  '');

  mobile.boot.stage-1.extraUtils = with pkgs; [
    { package = e2fsprogs; extraCommand = ""; }
  ];
}
