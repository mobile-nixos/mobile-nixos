{ config, lib, pkgs, ... }:

let
  enabled = config.filesystem == "fat32";
  inherit (lib)
    escapeShellArg
    mkIf
    mkMerge
    mkOption
    optionalString
    types
  ;
  inherit (config.helpers)
    chopDecimal
  ;
  type32bitHex = types.strMatching "[0-9a-fA-F]{1,8}";

  inherit (config) label sectorSize blockSize;
  inherit (config.fat32) partitionID;

  # Should these be configurable?
  # The default from `mkfs.fat`.
  reservedSectors = 32;

  # The default from `mkfs.fat`.
  hiddenSectors = 0;

  # The default from `mkfs.fat`.
  numberOfFats = 2;

  # Extra padding per FAT, a constant in code
  fatPadding = 4;

  # I have not been able to validate that it could be different from 1 for FAT32.
  # It seems the different values (e.g. 4) are for FAT12 and FAT16.
  # This is the only "bad" assumption here.
  clusterSize = 1;

  # Bash doesn't do floating point representations. Multiplications and divisions
  # are handled with enough precision that we can multiply and divide to get a precision.
  precision = 1000;
in
{
  options.fat32 = {
    partitionID = mkOption {
      type = types.nullOr type32bitHex;
      example = "2e24ec82";
      default = null;
      defaultText = "[Depends on the file system creation time]";
      description = ''
        Volume ID of the filesystem.

        The default is a number which depends on the file system creation time.
      '';
    };
  };

  config = mkMerge [
    { availableFilesystems = [ "fat32" ]; }
    (mkIf enabled {
      nativeBuildInputs = with pkgs.buildPackages; [
        dosfstools
        mtools
      ];

      blockSize = lib.mkDefault 512;
      sectorSize = lib.mkDefault 512;

      minimumSize = config.helpers.size.KiB 500;

      buildPhases = {
        checkPhase = ''
          # Always check and verify FS
          fsck.vfat -a "$img" || :
          fsck.vfat -vn "$img"
        '';

        filesystemPhase = ''
          fatSize=16
          if (( size > 1024*1024*32 )); then
            fatSize=32
          fi
          faketime -f "1970-01-01 00:00:01" mkfs.vfat \
            -F $fatSize \
            -R ${toString reservedSectors} \
            -h ${toString hiddenSectors} \
            -s ${toString (blockSize / sectorSize)} \
            -S ${toString sectorSize} \
            ${optionalString (partitionID != null) "-i ${partitionID}"} \
            ${optionalString (label != null) "-n ${escapeShellArg label}"} \
            "$img"
        '';

        copyPhase = ''
          (
          for f in ./* ./.*; do
            if [[ "$f" != "./." && "$f" != "./.." ]]; then
              faketime -f "1970-01-01 00:00:01" \
                mcopy -psv -i "$img" "$f" ::
            fi
          done
          )
        '';
      };

      computeMinimalSize = ''
        # `local size` is in bytes.

        # This amount is a static amount of reserved space.
        local static_reserved=${toString ( (reservedSectors + hiddenSectors) * sectorSize )}

        # This is a constant representing the relative reserved space ratio.
        local relative_reserved=${
          chopDecimal (
            precision - (
              1.0 * sectorSize / ((clusterSize * sectorSize) + (numberOfFats * fatPadding))
              # ^ forces floating point
            ) * precision
          )
        }
        # Rounds up the likely truncated result. At worst it's a bit more space.
        (( relative_reserved++ ))

        echo "static_reserved=$static_reserved" 1>&2
        echo "relative_reserved=$relative_reserved" 1>&2

        local reservedSize=$(( (static_reserved + size) * relative_reserved / ${toString precision} + static_reserved ))

        echo -n "Adding reservedSize: $size + $reservedSize = " 1>&2
        size=$((size + reservedSize))
        echo "$size" 1>&2
      '';

    })
  ];
}
