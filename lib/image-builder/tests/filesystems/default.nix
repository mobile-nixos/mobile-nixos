# Tests all known filesystems as empty, with defaults.
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
        size = size.MiB 10;
        # FIXME : this is wrong. Not all partition IDs have the same format.
        partitionID = "0123456789ABCDEF";
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
