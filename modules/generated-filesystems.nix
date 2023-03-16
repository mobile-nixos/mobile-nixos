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
          description = lib.mdDoc ''
            Type of the generated filesystem.
          '';
        };
        label = lib.mkOption {
          type = types.str;
          description = lib.mdDoc ''
            The label used by the generated rootfs, when generating a rootfs, and
            the filesystem label a Mobile NixOS system will look for by default.
          '';
        };
        id = lib.mkOption {
          type = types.str;
          description = lib.mdDoc ''
            The UUID used by the generated rootfs, when generating a rootfs.
          '';
        };
        populateCommands = lib.mkOption {
          type = types.lines;
          description = lib.mdDoc ''
            Commands used to fill the filesystem.

            `$PWD` is the root of the filesystem.
          '';
        };
        postProcess = lib.mkOption {
          type = types.lines;
          internal = true;
          description = lib.mdDoc ''
            Commands used to manipulate the filesystem after it has been
            created.
          '';
        };
        extraPadding = lib.mkOption {
          type = types.int;
          description = lib.mdDoc ''
            Extra padding to add to the filesystem image.
          '';
        };
        zstd = lib.mkOption {
          internal = true;
          type = types.bool;
          description = lib.mdDoc ''
            Whether to compress this artifact; used to work around size
            limitations in CI situations.
          '';
        };
        raw = lib.mkOption {
          internal = true;
          type = types.nullOr types.package;
          default = null;
          description = lib.mdDoc ''
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
      description = lib.mdDoc ''
        Filesystem definitions that will be created at build.
      '';
    };
    mobile.outputs.generatedFilesystems = lib.mkOption {
      type = with types; attrsOf package;
      internal = true;
      description = lib.mdDoc ''
        All generated filesystems from the build.
      '';
    };
    mobile.outputs.rootfs = lib.mkOption {
      type = types.package;
      visible = false;
      description = lib.mdDoc ''
        The rootfs image for the build.
      '';
    };
  };

  config = {
    mobile.outputs.generatedFilesystems = lib.attrsets.mapAttrs (name: {raw, type, id, label, ...} @ attrs:
    if raw != null then raw else
      filesystemFunctions."${type}" (attrs // {
        name = label;
        partitionID = id;
      })
    ) config.mobile.generatedFilesystems;

    mobile.outputs.rootfs = config.mobile.outputs.generatedFilesystems.rootfs;

    # Compatibility alias with the previous path.
    system.build.rootfs =
      builtins.trace "`system.build.rootfs` is being deprecated. Use `mobile.outputs.rootfs` instead. It will be removed after 2022-05"
      config.mobile.outputs.generatedFilesystems.rootfs
    ;
  };
}
