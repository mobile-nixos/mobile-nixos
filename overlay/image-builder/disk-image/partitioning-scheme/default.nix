{ config, lib, ... }:

let
  inherit (lib)
    mkOption
    types
  ;
in
{
  imports = [
    ./gpt
    ./mbr
  ];

  options = {
    availablePartitioningSchemes = mkOption {
      type = with types; listOf str;
      internal = true;
    };
    partitioningScheme = mkOption {
      type = types.enum config.availablePartitioningSchemes;
      description = lib.mdDoc ''
        Partitioning scheme for the disk image output.
      '';
    };
  };
}
