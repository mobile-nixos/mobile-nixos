{ config, lib, ... }:

let
  inherit (lib)
    mkOption
    types
  ;
in
{
  imports = [
    ./btrfs.nix
    ./ext4.nix
    ./fat32.nix
    ./squashfs.nix
  ];

  options = {
    availableFilesystems = mkOption {
      type = with types; listOf str;
      internal = true;
    };
    filesystem = mkOption {
      type = types.enum config.availableFilesystems;
      description = lib.mdDoc ''
        Filesystem used in this filesystem image.
      '';
    };
  };
}
