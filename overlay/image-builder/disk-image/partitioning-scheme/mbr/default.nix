{ config, lib, pkgs, ... }:

let
  enabled = config.partitioningScheme == "mbr";
  inherit (lib)
    mkIf
    mkMerge
    mkOption
    types
  ;
in
{
  options.mbr = {
    diskID = mkOption {
      type = types.strMatching (
        let hex = "[0-9a-fA-F]"; in
          "${hex}{8}"
      );
      default = null;
      description = ''
        Identifier for the disk.
      '';
    };
  };

  config = mkMerge [
    { availablePartitioningSchemes = [ "mbr" ]; }
    (mkIf enabled {
      output = pkgs.callPackage ./builder.nix {
        inherit config;
      };
    })
  ];
}
