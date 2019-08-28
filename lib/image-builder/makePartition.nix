{ stdenvNoCC, lib, writeText }:

/*  */ let scope = { "fileSystem.makePartition" =

let
  inherit (lib) optionals;
in

{
  name
  , size ? null
  , ...
} @ args:
let
  partName = name;
  partSize = toString size;
in
stdenvNoCC.mkDerivation (args // rec {
  # Do not inherit `size`; we don't want to accidentally use it. The `size` can
  # be dynamic depending on the contents.
  inherit partName;

  name = "partition-${partName}";
  filename = "${partName}.img";
  img = "${placeholder "out"}/${filename}";

  nativeBuildInputs = [
  ] ++ optionals (args ? nativeBuildInputs) args.nativeBuildInputs;

  buildCommand = ''
    # The default stdenv/generic clashes with `runHook`.
    # It doesn't override as expected.
    unset -f checkPhase

    mkdir -p $out

    echo
    echo "Building partition ${partName}"
    echo "With ${if size == null then "automatic size" else "${toString size} bytes"}"
    echo

    echo " -> Allocating space"
    truncate -s ${partSize} "$img"

    echo " -> Making filesystem"
    runHook filesystemPhase

    echo " -> Copying files"
    runHook copyPhase

    echo " -> Checking filesystem"
    echo "$checkPhase"
    runHook checkPhase

  ''
  + lib.optionalString ((builtins.getEnv "TEST_MODE") == "yes")
    "# test impure builds ${toString builtins.currentTime}"
  ;

})
    # mkdir -p $out/nix-support
    # cat ${writeText "${name}-metadata" (builtins.toJSON {
    #   inherit size;
    # })} > $out/nix-support/partition-metadata.json

/*  */ ;}; in scope."fileSystem.makePartition"
