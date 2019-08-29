# Expect: { "status": 1, "grep": "Either a size or populateCommands needs to be given to build a filesystem." }
{ pkgs ? import <nixpkgs> {} }:

let
  imageBuilder = pkgs.callPackage <image-builder> {};
in

with imageBuilder;

fileSystem.makeFAT32 {
  name = "whatever";
  partitionID = "0123456789ABCDEF";
}
