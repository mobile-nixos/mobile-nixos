{ config, lib, pkgs, ... }:

let
  enabled = config.filesystem == "ext4";
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

  inherit (config) label;
  inherit (config.ext4) partitionID;

  # Bash doesn't do floating point representations. Multiplications and divisions
  # are handled with enough precision that we can multiply and divide to get a precision.
  precision = 1000;

  makeFudge = f: toString (chopDecimal (f * precision));

  # This applies only to 256MiB and greater.
  # For smaller than 256MiB images the overhead from the FS is much greater.
  # This will also let *some* slack space at the end at greater sizes.
  # This is the value at 512MiB where it goes slightly down compared to 256MiB.
  fudgeFactor = makeFudge 0.05208587646484375;

  # This table was built using a script that built an image with `make_ext4fs`
  # for the given size in MiB, and recorded the available size according to `df`.
  smallFudgeLookup = lib.strings.concatStringsSep "\n" (lib.lists.reverseList(
    lib.attrsets.mapAttrsToList (size: factor: ''
      elif (( size > ${toString size} )); then
        fudgeFactor=${toString factor}
    '') {
    "${toString (config.helpers.size.MiB   5)}" = makeFudge 0.84609375;
    "${toString (config.helpers.size.MiB   8)}" = makeFudge 0.5419921875;
    "${toString (config.helpers.size.MiB  16)}" = makeFudge 0.288818359375;
    "${toString (config.helpers.size.MiB  32)}" = makeFudge 0.1622314453125;
    "${toString (config.helpers.size.MiB  64)}" = makeFudge 0.09893798828125;
    "${toString (config.helpers.size.MiB 128)}" = makeFudge 0.067291259765625;
    "${toString (config.helpers.size.MiB 256)}" = makeFudge 0.0518646240234375;
  }
  ));

  minimumSize = config.helpers.size.MiB 5;
in
{
  options.ext4 = {
    partitionID = mkOption {
      type = types.nullOr config.helpers.types.uuid;
      example = "45454545-4545-4545-4545-454545454545";
      default = null;
      description = lib.mdDoc ''
        Volume ID of the filesystem.
      '';
    };
  };

  config = mkMerge [
    { availableFilesystems = [ "ext4" ]; }
    (mkIf enabled {
      nativeBuildInputs = with pkgs.buildPackages; [
        e2fsprogs
        make_ext4fs
      ];

      blockSize = config.helpers.size.KiB 4;
      sectorSize = lib.mkDefault 512;

      inherit minimumSize;

      computeMinimalSize = ''
        # `local size` is in bytes.

        # We don't have a static reserved factor figured out. It is rather hard with
        # ext4fs as there are multiple factors increasing the overhead.
        local reservedSize=0
        local fudgeFactor=${toString fudgeFactor}
        
        # Instead we rely on a lookup table. See how it is built in the derivation file.
        if (( size < ${toString (config.helpers.size.MiB 256)} )); then
          echo "$size is smaller than 256MiB; using the lookup table." 1>&2
          
          # A bit of a hack, though allows us to build the lookup table using only elifs.
          if false; then
            :
          ${smallFudgeLookup}
          else
            # The data is smaller than 5MiB... The filesystem image size will likely
            # not be able to accomodate... here we handle it in another way.
            fudgeFactor=0
            echo "Fudge factor skipped for extra small partition. Instead increasing by a fixed amount." 1>&2
            size=$(( size + ${toString minimumSize}))
          fi
        fi

        local reservedSize=$(( size * $fudgeFactor / ${toString precision} ))

        echo "Fudge factor: $fudgeFactor / ${toString precision}" 1>&2
        echo -n "Adding reservedSize: $size + $reservedSize = " 1>&2
        size=$((size + reservedSize))
        echo "$size" 1>&2
      '';

      buildPhases = {
        copyPhase = ''
          faketime -f "1970-01-01 00:00:01" \
            make_ext4fs \
            -b $blockSize \
            -l $size \
            ${optionalString (partitionID != null) "-U ${partitionID}"} \
            ${optionalString (label != null) "-L ${escapeShellArg label}"} \
            "$img" \
            .
        '';

        checkPhase = ''
          EXT2FS_NO_MTAB_OK=yes faketime -f "1970-01-01 00:00:01" fsck.ext4 -y -f "$img" || :
          EXT2FS_NO_MTAB_OK=yes faketime -f "1970-01-01 00:00:01" fsck.ext4 -n -f "$img"
        '';
      };
    })
  ];
}
