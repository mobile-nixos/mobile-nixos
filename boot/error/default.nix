{ runCommand
, lib
, mruby
}:

let
  inherit (lib) concatMapStringsSep;

  # Select libs we need from the libs folder.
  libs = concatMapStringsSep " " (name: "${../lib}/${name}") [
    "lvgui/args.rb"
    "lvgui/fiddlier.rb"
    "lvgui/lvgl/*.rb"
    "lvgui/lvgui/*.rb"
    "lvgui/vtconsole.rb"
  ];
in

# mkDerivation will append something like -aarch64-unknown-linux-gnu to the
# derivation name with cross, which will break the mruby code loading.
# Since we don't need anything from mkDerivation, really, let's use runCommand.
runCommand "boot-error.mrb" {
  src = lib.cleanSource ./.;
  lib = lib.cleanSource ../recovery-menu/lib;

  nativeBuildInputs = [
    mruby
  ];
} ''
  mrbc \
    -o $out \
    ${libs} \
    $(find $lib -type f -name '*.rb' | sort) \
    $(find $src/lib -type f -name '*.rb' | sort) \
    $src/main.rb
''
