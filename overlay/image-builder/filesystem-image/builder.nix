{ stdenvNoCC, config, ncdu, tree }:

# This builder is heavily influenced by the configuration.
stdenvNoCC.mkDerivation (config.buildPhases // {
  inherit (config)
    name
    buildInputs
    filesystem
    label
    size
    minimumSize
    blockSize
    sectorSize
  ;

  nativeBuildInputs = config.nativeBuildInputs ++ [
    ncdu
    tree
  ];

  phases = config.buildPhasesOrder;

  img = placeholder "out";

  outputs = [ "out" "metadata" ];

  buildCommand = ''
    PS4=" $ "
    set -u

    header() {
      printf "\n:: %s\n\n" "$1"
    }

    ${config.builderFunctions}

    # The default stdenv/generic clashes with `runHook`.
    # It doesn't override as expected.
    unset -f checkPhase

    # Location where extra metadata about the filesystem can be stored.
    # Use for extra useful debugging data.
    mkdir -p $metadata

    # Location where the filesystem content will be copied to.
    mkdir -p files
    files="$(cd files; pwd)"

    for phase in ''${phases[@]}; do
      if [[ "$phase" != _* ]]; then
        header "Running $phase"
      fi
      runHook "$phase"
    done

    (
      cd "$files"
      faketime -f "1970-01-01 00:00:01" tree -a | xz > $metadata/tree.xz
      faketime -f "1970-01-01 00:00:01" ncdu -0x -o - | xz > $metadata/ncdu.xz
    )

    set +u
  '';

  passthru = {
    inherit (config) filesystem;
  };
})
