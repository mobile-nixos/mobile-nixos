# Tests all known filesystems as empty, with defaults.
# This test helps ensure the basic interface stays stable, and works.
{ pkgs ? import <nixpkgs> {} }:

let
  imageBuilder = pkgs.callPackage <image-builder> {};
  inherit (pkgs.lib.attrsets) mapAttrsToList;
  inherit (pkgs.lib.strings) concatStringsSep removePrefix;
  IDs = {
    FAT32 = "0123456789ABCDEF";
    ESP = "0123456789ABCDEF";
  };
in

with imageBuilder;

let
  cmds =
    mapAttrsToList (fn_name: fn:
    let
      fs = fn rec {
        name = removePrefix "make" fn_name;
        size = imageBuilder.size.MiB 10;
        partitionID = IDs."${name}";
      };
    in
    ''
      ln -s ${fs}/${fs.filename} $out/
    '') fileSystem;
in
  pkgs.runCommandNoCC "filesystems-test" {} ''
    mkdir -p $out/
    ${concatStringsSep "\n" cmds}
  ''
