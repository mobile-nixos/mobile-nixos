# Verifies that filesystems sized to be aligned works.
{ pkgs ? import <nixpkgs> {} }:

let
  inherit (pkgs) imageBuilder;
  makeNull = size: pkgs.runCommandNoCC "filesystems-test" {
    filename = "null.img";
    filesystemType = "FAT32"; # meh, good enough
  } ''
    mkdir -p $out
    dd if=/dev/zero of=$out/$filename bs=${toString size} count=1
  '';
in

with imageBuilder;

{
  one = diskImage.makeMBR {
    name = "diskimage";
    diskID = "012345678";
    partitions = [
      (makeNull (size.MiB 1))
      (makeNull (size.MiB 1))
    ];
  };
  nine = diskImage.makeMBR {
    name = "diskimage";
    diskID = "012345678";
    partitions = [
      (makeNull (size.MiB 9))
      (makeNull (size.MiB 9))
    ];
  };
  ten = diskImage.makeMBR {
    name = "diskimage";
    diskID = "012345678";
    partitions = [
      (makeNull (size.MiB 10))
      (makeNull (size.MiB 10))
    ];
  };
  eleven = diskImage.makeMBR {
    name = "diskimage";
    diskID = "012345678";
    partitions = [
      (makeNull (size.MiB 11))
      (makeNull (size.MiB 11))
    ];
  };
}
