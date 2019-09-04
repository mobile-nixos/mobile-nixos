{ stdenvNoCC, lib
, imageBuilder
, utillinux
}:

/*  */ let scope = { "diskImage.makeMBR" =

let
  inherit (lib) concatMapStringsSep optionalString;

  # List of known mappings of MBR partition types to filesystems.
  types = {
    "FAT32" =  "b";
    "ESP"   = "ef";
    "ext2"  = "83";
    "ext3"  = "83";
    "ext4"  = "83";
  };
in
{
  name
  , partitions
  # Without the prefixed `0x`
  , diskID
}:

let
  _name = name;

  eachPart = partitions: fn: (
    concatMapStringsSep "\n" (partition:
      fn partition
  ) partitions);

  # Default alignment.
  alignment = toString (imageBuilder.size.MiB 1);
in
stdenvNoCC.mkDerivation rec {
  name = "disk-image-${_name}";
  filename = "${_name}.img";
  img = "${placeholder "out"}/${filename}";

  nativeBuildInputs = [
    utillinux
  ];

  buildCommand = let
    # This fragment is used to compute the (aligned) size of the partition.
    # It is used *only* to track the tally of the space used, thus the starting
    # offset of the next partition. The filesystem sizes are untouched.
    sizeFragment = ''
      start=$totalSize
      size=$(($(du --apparent-size -B 512 "$input_img" | awk '{ print $1 }') * 512))
      size=$(( $(if (($size % ${alignment})); then echo 1; else echo 0; fi ) + size / ${alignment} ))
      size=$(( size * ${alignment} ))
      totalSize=$(( totalSize + size ))
      echo "start $start | size $size | totalSize $totalSize"
    '';
  in ''
    mkdir -p $out

    cat <<EOF > script.sfdisk
    label: dos
    grain: 1024
    label-id: 0x${diskID}
    EOF

    totalSize=${alignment}
    echo
    echo "Gathering information about partitions."
    ${eachPart partitions (partition: ''
      input_img="${partition}/${partition.filename}"
      ${sizeFragment}
      echo " -> ${partition.name}: $size / ${partition.filesystemType}"

      (
      # The size is /1024; otherwise it's in sectors.
      echo -n 'start='"$((start/1024))"'KiB'
      echo -n ', size='"$((size/1024))"'KiB'
      echo -n ', type=${types."${partition.filesystemType}"}'
      ${optionalString (partition ? bootable && partition.bootable)
          "echo -n ', bootable'"}
      echo "" # Finishes the command
      ) >> script.sfdisk
    '')}

    echo "--- script ----"
    cat script.sfdisk
    echo "--- script ----"

    echo
    echo "Making image, $totalSize bytes..."
    truncate -s $((totalSize)) $img
    sfdisk $img < script.sfdisk

    totalSize=${alignment}
    echo
    echo "Writing partitions into image"
    ${eachPart partitions (partition: ''
      input_img="${partition}/${partition.filename}"
      ${sizeFragment}
      echo " -> ${partition.name}: $size / ${partition.filesystemType}"

      echo "$start / $size"
      dd conv=notrunc if=$input_img of=$img seek=$((start/512)) count=$((size/512)) bs=512
    '')}

    echo
    echo "Information about the image:"
    ls -lh $img
    sfdisk -V --list $img
  '';
}

/*  */ ;}; in scope."diskImage.makeMBR"
