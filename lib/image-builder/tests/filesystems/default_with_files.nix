# Tests all known filesystems with files.
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
        partitionID = IDs."${name}";
        populateCommands = ''
          echo "I am ${name}." > file
          ls -lA
        '';
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

