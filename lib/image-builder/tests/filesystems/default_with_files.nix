# Tests all known filesystems with files.
# This test helps ensure the basic interface stays stable, and works.
{ pkgs ? import <nixpkgs> {} }:

let
  imageBuilder = pkgs.callPackage <image-builder> {};
  inherit (pkgs.lib.attrsets) mapAttrsToList;
  inherit (pkgs.lib.strings) concatStringsSep removePrefix;
in

with imageBuilder;

let
  cmds =
    mapAttrsToList (name: fn:
    let
      fs = fn {
        name = removePrefix "make" name;
        # FIXME : this is wrong. Not all partition IDs have the same format.
        partitionID = "0123456789ABCDEF";
        populateCommands = ''
          echo "I am ${name}." > file
          ls -lA
        '';
      };
    in
    ''
      cp ${fs}/${fs.filename} $out/
    '') fileSystem;
in
  pkgs.runCommandNoCC "filesystems-test" {} ''
    mkdir -p $out/
    ${concatStringsSep "\n" cmds}
  ''

