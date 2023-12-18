{ stdenvNoCC
, lib
, utillinux
, config
}:

let
  inherit (lib)
    optionalString
  ;
  inherit (config.helpers)
    each
  ;
  inherit (config)
    partitions
  ;
in
stdenvNoCC.mkDerivation rec {
  inherit (config)
    name
    alignment
    sectorSize
    location
    additionalCommands
  ;
  inherit (config.mbr)
    diskID
  ;

  nativeBuildInputs = [
    utillinux
  ];

  buildCommand = let
    # This fragment is used to compute the (aligned) size of the partition.
    # It is used *only* to track the tally of the space used, thus the starting
    # offset of the next partition. The filesystem sizes are untouched.
    sizeFragment = partition: ''
      ${if (partition ? offset && partition.offset != null) then ''
        # If a partition asks to start at a specific offset, restart tally at
        # that location.
        offset=$((${toString partition.offset}))

        if (( offset < totalSize )); then
          echo "Partition '${partition.name}' wanted to start at $offset while we were already at $totalSize"
          echo "As of right now, partitions need to be in order."
          exit 1
        else
          totalSize=$offset
        fi
        start=$totalSize
        # *by design* we're not aligning the start of the partition here if an
        # offset was given.
      '' else ''
        # Assume we start where we left off...
        start=$totalSize
        # Align to the nearest alignment
        if (( start % alignment )); then
          start=$(( start + (alignment - start % alignment) ))
        fi
      ''}
      ${
        if (partition ? length && partition.length != null) then
        ''size=$((${toString partition.length}))''
        else
        ''size=$(($(du --apparent-size -B 512 "$input_img" | awk '{ print $1 }') * 512))''
      }
      size=$(( $(if ((size % alignment)); then echo 1; else echo 0; fi ) + size / alignment ))
      size=$(( size * alignment ))
      totalSize=$(( totalSize + size ))
      # Align the end too
      if (( totalSize % alignment )); then
        totalSize=$(( totalSize + (alignment - totalSize % alignment) ))
      fi
      echo "Partition: start $start | size $size | totalSize $totalSize"
    '';

    # This fragment is used to add the desired gap to `totalSize`.
    # We're setting `start` and `size` only to mirror the information shown
    # for partitions.
    gapFragment = partition: ''
      start=$totalSize
      size=${toString partition.length}
      totalSize=$(( totalSize + size ))
      echo "Gap: start $start | size $size | totalSize $totalSize"
    '';
  in ''
    set -u

    # Referring to `$out` is forbidden, use `$img`.
    # This is because the image path may or may not be at the root.
    img="$out$location"
    out_path="$out"
    unset out
    mkdir -p "$(dirname "$img")"

    # LBA0 contains the MBR.
    mbrSize=$((1*512))

    cat <<EOF > script.sfdisk
    label: dos
    unit: sectors
    first-lba: $(( mbrSize % sectorSize ? mbrSize / sectorSize + 1 : mbrSize / sectorSize ))
    sector-size: $sectorSize
    grain: $alignment
    ${optionalString (diskID != null) ''
    label-id: ${diskID}
    ''}
    EOF

    totalSize=$((mbrSize))
    echo
    echo "Gathering information about partitions."
    ${each partitions (partition:
      if partition ? isGap && partition.isGap then
        (gapFragment partition)
      else
        ''
          input_img="${if partition.raw != null then partition.raw else ""}"
          ${sizeFragment partition}
          echo ' -> '${lib.escapeShellArg partition.name}": $size / ${if partition ? filesystemType then partition.filesystemType else ""}"

          (
          echo -n 'start='"$((start/sectorSize))"
          echo -n ', size='"$((size/sectorSize))"
          echo -n ', type=${partition.partitionType}'
          ${optionalString (partition ? bootable && partition.bootable)
              ''echo -n ', bootable' ''}
          echo "" # Finishes the command
          ) >> script.sfdisk
        ''
    )}

    # Allow space for secondary partition table / header.
    totalSize=$(( totalSize + mbrSize ))

    echo "--- script ----"
    cat script.sfdisk
    echo "--- script ----"

    echo
    echo "Making image, $totalSize bytes..."
    truncate -s $((totalSize)) $img

    sfdisk $img < script.sfdisk

    totalSize=$((mbrSize))
    echo
    echo "Writing partitions into image"
    ${each partitions (partition: 
      if !(partition ? raw && partition.raw != null) && partition ? isGap && partition.isGap then
        (gapFragment partition)
      else
        ''
          input_img="${if partition.raw != null then partition.raw else ""}"
          if [[ "$input_img" == "" ]]; then
            input_img="/dev/zero"
          fi
          ${sizeFragment partition}
          echo ' -> '${lib.escapeShellArg partition.name}": $size / ${if partition ? filesystemType then partition.filesystemType else ""}"

          echo "$start / $size"
          dd conv=notrunc if=$input_img of=$img seek=$((start/512)) count=$((size/512)) bs=512
        ''
    )}

    echo
    echo "Information about the image:"
    ls -lh $img
    sfdisk -V --list $img

    runHook additionalCommands

    set +u
  '';
}
