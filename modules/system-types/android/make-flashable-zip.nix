{ runCommandNoCC, writeText, zip, mobile-nixos }:

let
  inherit (mobile-nixos) android-flashable-zip-binaries;
in

{ script, copyFiles, name }:

let
  update-script = writeText "update-script.rb" script;
in
runCommandNoCC name {
  nativeBuildInputs = [
    zip
  ];
} ''
  mkdir -p zip
  (
    echo ":: Archiving flashable zip"
    PS4=" $ "
    set -x
    cd zip
    mkdir -p META-INF/com/google/android
    ${copyFiles}
    cp ${update-script} update-script.rb
    cp ${android-flashable-zip-binaries}/bin/update-binary META-INF/com/google/android/update-binary
    zip $out $(find | sort)
  )
''
