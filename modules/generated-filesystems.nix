# Generated filesystems, contrary to filesystems on a configured system.
#
# This contains the machinery to produce filesystem images.
{ config, lib, pkgs, ...}:

let
  inherit (lib) types;

  filesystemFunctions = {
    "ext4" = pkgs.imageBuilder.fileSystem.makeExt4;
    "btrfs" = pkgs.imageBuilder.fileSystem.makeBtrfs;
  };

  filesystemSubmodule =
    { name, config, ... }: {
      options = {
        type = lib.mkOption {
          type = types.enum [ "ext4" "btrfs" ];
          description = ''
            Type of the generated filesystem.
          '';
        };
        label = lib.mkOption {
          type = types.str;
          description = ''
            The label used by the generated rootfs, when generating a rootfs, and
            the filesystem label a Mobile NixOS system will look for by default.
          '';
        };
        id = lib.mkOption {
          type = types.str;
          description = ''
            The UUID used by the generated rootfs, when generating a rootfs.
          '';
        };
        populateCommands = lib.mkOption {
          type = types.lines;
          description = ''
            Commands used to fill the filesystem.

            `$PWD` is the root of the filesystem.
          '';
        };
        postProcess = lib.mkOption {
          type = types.lines;
          internal = true;
          description = ''
            Commands used to manipulate the filesystem after it has been
            created.
          '';
        };
        extraPadding = lib.mkOption {
          type = types.int;
          description = ''
            Extra padding to add to the filesystem image.
          '';
        };
        zstd = lib.mkOption {
          internal = true;
          type = types.bool;
          description = ''
            Whether to compress this artifact; used to work around size
            limitations in CI situations.
          '';
        };
        raw = lib.mkOption {
          internal = true;
          type = types.nullOr types.package;
          default = null;
          description = ''
            Use an output directly rather than creating it from the options.
          '';
        };
      };
      config = {
      };
    }
  ;
in
{
  options = {
    mobile.generatedFilesystems = lib.mkOption {
      type = types.attrsOf (types.submodule filesystemSubmodule);
      description = ''
        Filesystem definitions that will be created at build.
      '';
    };
  };

  config = {
    system.build.generatedFilesystems = lib.attrsets.mapAttrs (name: {raw, type, id, label, ...} @ attrs:
    if raw != null then raw else
      filesystemFunctions."${type}" (attrs // {
        name = label;
        partitionID = id;
      })
    ) config.mobile.generatedFilesystems;

    # Compatibility alias with the previous path.
    system.build.rootfs = config.system.build.generatedFilesystems.rootfs;
  };
}
