# Tests all known filesystems with files.
# This test helps ensure the basic interface stays stable, and works.
{ pkgs ? import <nixpkgs> {} }:

let
  inherit (pkgs) imageBuilder;
  inherit (pkgs.lib.attrsets) mapAttrsToList;
  inherit (pkgs.lib.strings) concatStringsSep removePrefix;
  IDs = {
    FAT32 = "0123456789ABCDEF";
    ESP = "0123456789ABCDEF";
    Ext4 = "44444444-4444-4444-1324-123456789098";
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

