{
  pkgs ? import ./pkgs.nix
}:

let
  inherit (pkgs) stdenv mobile-nixos-process-doc rsync;

  # Styles, built from a preprocessor.
  styles = pkgs.callPackage ./_support/styles { };

  # Asciidoc source for the devices section.
  devices = pkgs.callPackage ./_support/devices { };
in

stdenv.mkDerivation {
  name = "mobile-nixos-docs";
  src = ./.;

  buildInputs = [
    mobile-nixos-process-doc
    rsync
  ];

  buildPhase = ''
    # Removes the internal notes.
    rm -f README.md

    # Replace it in-place with the repo README.
    cat >> README.adoc <<EOF
    README.adoc
    ===========
    include::_support/common.inc[]
    :relative_file_path: README.adoc

    EOF

    tail -n +3 ${../README.adoc} >> README.adoc

    # Copies the generated asciidoc source for the devices.
    cp -prf ${devices}/devices devices

    # Use our pipeline to process the docs.
    process-doc "**/*.adoc" "**/*.md" \
      --styles-dir="${styles}" \
      --output-dir="$out"

    rsync --prune-empty-dirs --verbose --archive --include="*.jpeg" --include="*/" --exclude="*" . $out/
  '';

  dontInstall = true;
}
