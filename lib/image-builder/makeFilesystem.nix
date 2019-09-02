{ stdenvNoCC, lib, writeText }:

/*  */ let scope = { "fileSystem.makeFilesystem" =

let
  inherit (lib) optionals optionalString assertMsg;
in

{
  name
  # The populate commands are executed in a subshell. The CWD at the star is the
  # public API to know where to add files that will be added to the image.
  , populateCommands ? null
  # When size is not given, it is assumed that `populateCommands` will populate
  # the filesystem.
  , blockSize
  , size ? null
  , ...
} @ args:

assert lib.asserts.assertMsg
  (size !=null || populateCommands != null)
  "Either a size or populateCommands needs to be given to build a filesystem.";

let
  partName = name;
in
stdenvNoCC.mkDerivation (args // rec {
  # Do not inherit `size`; we don't want to accidentally use it. The `size` can
  # be dynamic depending on the contents.
  inherit partName blockSize;

  name = "partition-${partName}";
  filename = "${partName}.img";
  img = "${placeholder "out"}/${filename}";

  nativeBuildInputs = [
  ] ++ optionals (args ? nativeBuildInputs) args.nativeBuildInputs;

  buildCommand = ''
    sum-lines() {
      local acc=0
      while read -r number; do
          acc=$((acc+number))
      done

      echo "$acc"
    }


    # The default stdenv/generic clashes with `runHook`.
    # It doesn't override as expected.
    unset -f checkPhase

    mkdir -p $out
    mkdir -p files

    ${optionalString (populateCommands != null) ''
    echo
    echo "Populating disk image"
    echo
    (
      cd files
      ${populateCommands}
    )
    ''}
    ${optionalString (size == null) ''
      # Size rounded in blocks. This assumes all files are to be rounded to a
      # multiple of blockSize.
      size=$(du -akh --block-size "$blockSize" . | cut -f1 | sum-lines)
      # Size in bytes
      size=$((size * blockSize))
    ''}

    if (( size < minimumSize )); then
      size=$minimumSize
      echo "WARNING: partition was too small, size increased to $minimumSize bytes."
    fi

    echo
    echo "Building partition ${partName}"
    echo "With ${if size == null
      then "automatic size ($size bytes)"
      else "$size bytes"
    }"
    echo

    echo " -> Allocating space"
    truncate -s $size "$img"

    echo " -> Making filesystem"
    runHook filesystemPhase

    echo " -> Copying files"
    (
      cd files
      runHook copyPhase
    )

    echo " -> Checking filesystem"
    echo "$checkPhase"
    runHook checkPhase

  '';

})
    # mkdir -p $out/nix-support
    # cat ${writeText "${name}-metadata" (builtins.toJSON {
    #   inherit size;
    # })} > $out/nix-support/partition-metadata.json

/*  */ ;}; in scope."fileSystem.makeFilesystem"
