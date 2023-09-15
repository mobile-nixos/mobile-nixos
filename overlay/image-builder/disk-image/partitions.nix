{ config, lib, pkgs, ... }:

let
  inherit (lib)
    mkIf
    mkMerge
    mkOption
    types
  ;
  listEntrySubmodule = {
    options = {
    };
  };

  inherit (config) helpers;

  partitionSubmodule = { name, config, ... }: {
    options = {
      name = mkOption {
        type = types.str;
        description = lib.mdDoc ''
          Identifier for the partition.
        '';
      };

      partitionLabel = mkOption {
        type = types.str;
        default = config.name;
        defaultText = lib.literalExpression "config.name";
        description = lib.mdDoc ''
          Partition label on supported partition schemes. Defaults to ''${name}.

          Not to be confused with _filesystem_ label.
        '';
      };

      partitionUUID = mkOption {
        type = types.nullOr helpers.types.uuid;
        default = null;
        description = lib.mdDoc ''
          Partition UUID, for supported partition schemes.

          Not to be confused with _filesystem_ UUID.

          Not to be confused with _partitionType_.
        '';
      };

      length = mkOption {
        type = types.nullOr types.int;
        default = null;
        description = lib.mdDoc ''
          Size in bytes for the partition.

          Defaults to the filesystem image length (computed at runtime).
        '';
      };

      offset = mkOption {
        type = types.nullOr types.int;
        default = null;
        description = lib.mdDoc ''
          Offset (in bytes) the partition starts at.

          Defaults to the next aligned location on disk.
        '';
      };

      partitionType = mkOption {
        type = types.oneOf [
          helpers.types.uuid
          (types.strMatching "[0-9a-fA-F]{2}")
        ];
        default = "0FC63DAF-8483-4772-8E79-3D69D8477DE4";
        defaultText = "Linux filesystem data (0FC63DAF-8483-4772-8E79-3D69D8477DE4)";
        description = lib.mdDoc ''
          Partition type UUID.

          Not to be confused with _partitionUUID_.

          See: https://en.wikipedia.org/wiki/GUID_Partition_Table#Partition_type_GUIDs
        '';
      };

      bootable = mkOption {
        type = types.bool;
        default = false;
        description = lib.mdDoc ''
          Sets the "legacy bios bootable flag" on the partition.
        '';
      };

      requiredPartition = mkOption {
        type = types.bool;
        default = false;
        description = lib.mdDoc ''
          For GPT, sets the Required Partition attribute on the partition.
        '';
      };

      filesystem = mkOption {
        type = types.nullOr (types.submodule ({
          imports = [ ../filesystem-image ];
          _module.args.pkgs = pkgs;
        }));
        default = null;
        description = lib.mdDoc ''
          A filesystem image configuration.

          The filesystem image produced by this configuration is the default
          value for the `raw` submodule option, unless overriden.
        '';
      };

      isGap = mkOption {
        type = types.bool;
        default = false;
        description = lib.mdDoc ''
          When set to true, only the length attribute is used, and describes
          an unpartitioned span in the disk image.
        '';
      };

      raw = mkOption {
        type = with types; nullOr (oneOf [ package path ]);
        defaultText = "[contents of the filesystem attribute]";
        default = null;
        description = lib.mdDoc ''
          Raw image to be used as the partition content.

          By default uses the output of the `filesystem` submodule.
        '';
      };
    };

    config = mkMerge [
      (mkIf (!config.isGap && config.filesystem != null) {
        raw = lib.mkDefault config.filesystem.output;
      })
    ];
  };

in
{
  options = {
    partitions = mkOption {
      type = with types; listOf (submodule partitionSubmodule);
      description = lib.mdDoc ''
        List of partitions to include in the disk image.
      '';
    };
  };
}
