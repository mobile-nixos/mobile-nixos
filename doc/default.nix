{ pkgs ? import ../pkgs.nix { } }:
if pkgs == null then (builtins.throw "The `pkgs` argument needs to be provided to doc/default.nix") else

let pkgs' = pkgs; in # Break the cycle
let
  pkgs = pkgs'.appendOverlays [
    (final: super: {
      mobile-nixos-process-doc = final.callPackage ./_support/converter {};
    })
  ];
in

let
  inherit (pkgs) stdenv mobile-nixos-process-doc rsync;

  # Styles, built from a preprocessor.
  styles = pkgs.callPackage ./_support/styles { };

  # Asciidoc source for the devices section.
  devices = pkgs.callPackage ./_support/devices { };

  # Asciidoc source for the options section.
  options = pkgs.callPackage ./_support/options { };
in

stdenv.mkDerivation {
  name = "mobile-nixos-docs";
  src = ./.;

  buildInputs = [
    mobile-nixos-process-doc
    rsync
  ];

  buildPhase = ''
    export LANG=C.UTF-8

    # Removes the internal notes.
    rm -f README.md

    # Replace it in-place with the repo README.
    cat >> index.adoc <<EOF
    = Mobile NixOS
    include::_support/common.inc[]

    EOF
    tail -n +4 ${../README.adoc} >> index.adoc

    # The title needs to be first
    head -n1 ${../CONTRIBUTING.adoc} > contributing.adoc

    # Then we're adding our common stuff
    cat >> contributing.adoc <<EOF
    include::_support/common.inc[]
    EOF

    # Then continuing with the file.
    tail -n +2 ${../CONTRIBUTING.adoc} >> contributing.adoc

    # Copies the generated asciidoc source for the devices.
    cp -prf ${devices}/devices devices

    # Copies the generated asciidoc source for the options.
    cp -prf ${options}/options options

    # Use our pipeline to process the docs.
    process-doc "**/*.adoc" "**/*.md" \
      --styles-dir="${styles}" \
      --output-dir="$out"
  '';

  installPhase = ''
    rsync --prune-empty-dirs --verbose --archive \
      --exclude="*.src.svg" \
      --include="*.svg" \
      --include="*.jpeg" \
      --include="*.png" \
      --include="*/" --exclude="*" . $out/

    (
      cd $out
      if grep -RIi "$NIX_BUILD_TOP"; then
        echo "error: References to $NIX_BUILD_TOP found in output:"
        grep -RIi "$NIX_BUILD_TOP"
        exit 1
      fi
    )
  '';
}
