{ runCommand
, lib
, mruby
}:

# mkDerivation will append something like -aarch64-unknown-linux-gnu to the
# derivation name with cross, which will break the mruby code loading.
# Since we don't need anything from mkDerivation, really, let's use runCommand.
runCommand "boot-gui.mrb" {
  src = lib.cleanSource ./.;

  nativeBuildInputs = [
    mruby
  ];
} ''
  mrbc \
    -o $out \
    $(find $src/lib -type f -name '*.rb' | sort) \
    $src/main.rb
''
