{ config, lib, pkgs, ... }:

let
  enabled = config.filesystem == "squashfs";
  inherit (lib)
    escapeShellArg
    mkIf
    mkMerge
    mkOption
    optionalString
    types
  ;

  inherit (config) label sectorSize blockSize;
  inherit (config.squashfs)
    compression
    compressionParams
  ;
in
{
  options.squashfs = {
    compression = mkOption {
      type = types.enum [
        # Uses the name used in the -comp param
        "gzip"
        "xz"
        "zstd"
      ];
      default = "xz";
      description = lib.mdDoc ''
        Volume ID of the filesystem.
      '';
    };
    compressionParams = mkOption {
      type = types.str;
      internal = true;
    };
  };

  config = mkMerge [
    { availableFilesystems = [ "squashfs" ]; }
    (mkIf enabled {
      squashfs.compressionParams = mkMerge [
        (mkIf (compression == "xz") "-Xdict-size 100%")
        (mkIf (compression == "zstd") "-Xcompression-level 6")
      ];

      nativeBuildInputs = with pkgs.buildPackages; [
        squashfsTools
      ];

      # NixOS's make-squashfs uses 1MiB
      # mksquashfs's help says its default is 128KiB
      blockSize = config.helpers.size.MiB 1;
      # This is actually unused (and irrelevant)
      sectorSize = lib.mkDefault 512;
      minimumSize = 0;

      computeMinimalSize = "";

      buildPhases = {
        copyPhase = ''
          # The empty pre-allocated file will confuse mksquashfs
          rm "$img"

          (
          # This also activates dotglob automatically.
          # Using this means hidden files will be added too.
          GLOBIGNORE=".:.."

          # Using `.` as the input will put the PWD, including its name
          # in the root of the filesystem.
          mksquashfs \
            * \
            "$img" \
            -info \
            -b "$blockSize" \
            -no-hardlinks -keep-as-directory -all-root \
            -comp "${compression}" ${compressionParams} \
            -processors $NIX_BUILD_CORES                                         
          )
        '';
      };
    })
  ];
}
