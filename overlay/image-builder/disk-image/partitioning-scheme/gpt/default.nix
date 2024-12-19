{ config, lib, pkgs, ... }:

let
  enabled = config.partitioningScheme == "gpt";
  inherit (lib)
    mkIf
    mkMerge
    mkOption
    types
  ;
in
{
  options.gpt = {
    diskID = mkOption {
      type = types.nullOr config.helpers.types.uuid;
      default = null;
      description = ''
        Identifier for the disk.
      '';
    };

    partitionEntriesCount = mkOption {
      type = types.int;
      default = 128;
      description = ''
        Number of partitions in the partition table.

        The default value is likely appropriate.
      '';
    };

    hybridMBR = mkOption {
      type = with types; listOf str;
      default = [];
      example = [ "1" "3" "6" "EE" ];
      description = ''
        Creates an hybrid MBR with the given (string) partition numbers.

        Up to three partitions can be present in the hybrid MBR, an additional
        special partition can be placed last, named `EE`. When `EE` is present
        last the protective partition for the GPT will be placed last.

        See `man sgdisk`
      '';
    };
  };

  config = mkMerge [
    { availablePartitioningSchemes = [ "gpt" ]; }
    (mkIf enabled {
      output = pkgs.callPackage ./builder.nix {
        inherit config;
      };
    })
  ];
}
