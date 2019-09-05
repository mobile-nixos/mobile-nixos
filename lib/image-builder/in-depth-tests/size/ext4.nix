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
  eight = fileSystem.makeExt4 {
    name = "eight";
    partitionID = "44444444-4444-4444-0000-000000000008";
    populateCommands = ''
      ${makeNull (imageBuilder.size.MiB 8)}
    '';
  };

  eleven = fileSystem.makeExt4 {
    name = "eleven";
    partitionID = "44444444-4444-4444-0000-000000000011";
    populateCommands = ''
      ${makeNull (imageBuilder.size.MiB 11)}
    '';
  };

  sixteen = fileSystem.makeExt4 {
    name = "sixteen";
    partitionID = "44444444-4444-4444-0000-000000000016";
    populateCommands = ''
      ${makeNull (imageBuilder.size.MiB 16)}
    '';
  };

  one_twenty_eight = fileSystem.makeExt4 {
    name = "one_twenty_eight";
    partitionID = "44444444-4444-4444-0000-000000000128";
    populateCommands = ''
      ${makeNull (imageBuilder.size.MiB 128)}
    '';
  };

  two_fifty_six = fileSystem.makeExt4 {
    name = "two_fifty_six";
    partitionID = "44444444-4444-4444-0000-000000000256";
    populateCommands = ''
      ${makeNull (imageBuilder.size.MiB 256)}
    '';
  };

  five_twelve = fileSystem.makeExt4 {
    name = "five_twelve";
    partitionID = "44444444-4444-4444-0000-000000000512";
    populateCommands = ''
      ${makeNull (imageBuilder.size.MiB 512)}
    '';
  };

  with_space = fileSystem.makeExt4 {
    name = "with_space";
    partitionID = "44444444-4444-4444-0000-000000000005";
    populateCommands = ''
      ${makeNull (imageBuilder.size.MiB 5)}
    '';
    extraPadding = size.MiB 10;
  };

  # Fills 512 MiB (the downard slump in the high fudge factor) with 512 1MiB
  # files so we ensure the filesystem overhead is accounted for.
  multiple-files = fileSystem.makeExt4 {
    name = "multiple-files";
    partitionID = "44444444-4444-4444-0000-000000000512";
    populateCommands = ''
      for i in {1..512}; do
        dd if=/dev/zero of=./$i.img bs=${toString (imageBuilder.size.MiB 1)} count=1
      done
    '';
  };
}
