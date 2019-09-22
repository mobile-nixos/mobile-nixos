# Ensures we can fit stuff in an ext4 image.
{ pkgs ? import <nixpkgs> {} }:

let
  inherit (pkgs) imageBuilder;
  makeNull = size: let
    filename = "null.img";
    filesystemType = "FAT32"; # meh, good enough
  in
  ''
    mkdir -p $out
    dd if=/dev/zero of=./${toString size}.img bs=${toString size} count=1
  '';
in

with imageBuilder;

{
  one = fileSystem.makeExt4 {
    name = "one";
    partitionID = "44444444-4444-4444-0000-000000000001";
    populateCommands = ''
      ${makeNull (imageBuilder.size.MiB 1)}
    '';
  };
  two = fileSystem.makeExt4 {
    name = "two";
    partitionID = "44444444-4444-4444-0000-000000000002";
    populateCommands = ''
      ${makeNull (imageBuilder.size.MiB 2)}
    '';
  };
  three = fileSystem.makeExt4 {
    name = "three";
    partitionID = "44444444-4444-4444-0000-000000000003";
    populateCommands = ''
      ${makeNull (imageBuilder.size.MiB 3)}
    '';
  };
  four = fileSystem.makeExt4 {
    name = "four";
    partitionID = "44444444-4444-4444-0000-000000000004";
    populateCommands = ''
      ${makeNull (imageBuilder.size.MiB 4)}
    '';
  };
  five = fileSystem.makeExt4 {
    name = "five";
    partitionID = "44444444-4444-4444-0000-000000000005";
    populateCommands = ''
      ${makeNull (imageBuilder.size.MiB 5)}
    '';
  };
  # This is the boundary where otherwise it would begin to fail.
  five_plus_one = fileSystem.makeExt4 {
    name = "five_plus_one";
    partitionID = "44444444-4444-4444-0001-000000000005";
    populateCommands = ''
      ${makeNull ((imageBuilder.size.MiB 5) + 1)}
    '';
  };
  six = fileSystem.makeExt4 {
    name = "six";
    partitionID = "44444444-4444-4444-0000-000000000006";
    populateCommands = ''
      ${makeNull (imageBuilder.size.MiB 6)}
    '';
  };
  # For bigger tests, see in-depth-tests
}
