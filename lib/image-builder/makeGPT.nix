{ stdenvNoCC, lib
, imageBuilder
, vboot_reference
}:

/*  */ let scope = { "diskImage.makeGPT" =

let
  inherit (lib) concatMapStringsSep optionalString;

  # List of known mappings of GPT partition types to filesystems.
  # This is not exhaustive, only used as a default.
  # See also: https://sourceforge.net/p/gptfdisk/code/ci/master/tree/parttypes.cc
  types = {
    "FAT32" = "EBD0A0A2-B9E5-4433-87C0-68B6B72699C7";
    "ESP"   = "C12A7328-F81F-11D2-BA4B-00A0C93EC93B";
    "LUKS"  = "CA7D7CCB-63ED-4C53-861C-1742536059CC";
    "ext2"  = "0FC63DAF-8483-4772-8E79-3D69D8477DE4";
    "ext3"  = "0FC63DAF-8483-4772-8E79-3D69D8477DE4";
    "ext4"  = "0FC63DAF-8483-4772-8E79-3D69D8477DE4";
  };
in
{
  name
  , partitions
  , diskID
  , headerHole ? 0 # in bytes
}:

let
  _name = name;

  eachPart = partitions: fn: (
    concatMapStringsSep "\n" (partition:
      fn partition
  ) partitions);

  # Default alignment.
  alignment = toString (imageBuilder.size.MiB 1);

  image = partition: 
    if lib.isDerivation partition then
      "${partition}/${partition.filename}"
    else
      partition.filename
  ;
in
stdenvNoCC.mkDerivation rec {
  name = "disk-image-${_name}";
  filename = "${_name}.img";
  img = "${placeholder "out"}/${filename}";

  nativeBuildInputs = [
    vboot_reference
  ];

  buildCommand = let
    # This fragment is used to compute the (aligned) size of the partition.
    # It is used *only* to track the tally of the space used, thus the starting
    # offset of the next partition. The filesystem sizes are untouched.
    sizeFragment = partition: ''
      start=$totalSize
      ${
        if partition ? length then
        ''size=$((${toString partition.length}))''
        else
        ''size=$(($(du --apparent-size -B 512 "$input_img" | awk '{ print $1 }') * 512))''
      }
      size=$(( $(if (($size % ${alignment})); then echo 1; else echo 0; fi ) + size / ${alignment} ))
      size=$(( size * ${alignment} ))
      totalSize=$(( totalSize + size ))
      echo "Partition: start $start | size $size | totalSize $totalSize"
    '';

    # This fragment is used to add the desired gap to `totalSize`.
    # We're setting `start` and `size` only to mirror the information shown
    # for partitions.
    # Do note that gaps are always aligned, so two gaps sized half the alignment
    # would create 2× the space expected.
    # What may *instead* be done at one point is always align `start` for partitions.
    gapFragment = partition: ''
      start=$totalSize
      size=${toString partition.length}
      size=$(( $(if (($size % ${alignment})); then echo 1; else echo 0; fi ) + size / ${alignment} ))
      totalSize=$(( totalSize + size ))
      echo "Gap: start $start | size $size | totalSize $totalSize"
    '';
  in ''
    mkdir -p $out

    # 34 is the base GPT header size, as added to -p by cgpt.
    gptSize=$((${toString headerHole} + 34*512))

    touch commands.sh

    cat <<EOF > commands.sh
    # Zeroes the GPT
    cgpt create -z $img

    # Create the GPT with space if desired
    cgpt create -p ${toString (headerHole / 512)} $img

    # Add the PMBR
    cgpt boot -p $img

    EOF

    totalSize=$((gptSize))
    echo
    echo "Gathering information about partitions."
    ${eachPart partitions (partition:
      if partition ? isGap && partition.isGap then
        (gapFragment partition)
      else
        ''
          input_img="${image partition}"
          ${sizeFragment partition}
          echo " -> ${partition.name}: $size / ${if partition ? filesystemType then partition.filesystemType else ""}"


          (
          printf "cgpt add"
          printf " -b %s" "$((start/512))"
          printf " -s %s" "$((size/512))"
          printf " -t %s" '${
            if partition ? partitionType then
              partition.partitionType
            else
              types.${partition.filesystemType}
          }'
          ${optionalString (partition ? partitionUUID)
              "printf ' -u %s' '${partition.partitionUUID}'"}
          ${optionalString (partition ? bootable && partition.bootable)
              "printf ' -B 1'"}
          ${optionalString (partition ? partitionLabel)
              "printf ' -l \"%s\"' '${partition.partitionLabel}'"}
          printf " $img\n"
          ) >> commands.sh
        ''
    )}

    # Allow space for secondary partition table / header.
    totalSize=$(( totalSize + 34*512 ))

    echo "--- script ----"
    cat commands.sh
    echo "--- script ----"

    echo
    echo "Making image, $totalSize bytes..."
    truncate -s $((totalSize)) $img

    PS4=" > " sh -x commands.sh

    totalSize=$((gptSize))
    echo
    echo "Writing partitions into image"
    ${eachPart partitions (partition: 
      if partition ? isGap && partition.isGap then
        (gapFragment partition)
      else
        ''
          input_img="${image partition}"
          ${sizeFragment partition}
          echo " -> ${partition.name}: $size / ${if partition ? filesystemType then partition.filesystemType else ""}"

          echo "$start / $size"
          dd conv=notrunc if=$input_img of=$img seek=$((start/512)) count=$((size/512)) bs=512
        ''
    )}

    echo
    echo "Information about the image:"
    ls -lh $img
    cgpt show $img
  '';
}

/*  */ ;}; in scope."diskImage.makeGPT"
