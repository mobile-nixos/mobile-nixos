# Verifies that filesystems sized to be unaligned will work.
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

# Through empirical testing, it was found out that the defaults from `sfdisk`
# are not as documented.
# First of all, on small disks no alignment will be made.
# Starting with 3MiB (empirically derived) alignment will be made.
# The alignment is documented as being based on the I/O limits. It seems like
# for files it ends up causing alignments at the 2MiB boundaries.
# Such, `grain: 1024` has to be set to configure sfdisk for the sane default
# documented in its manpage
#
# > grain  Specify minimal size in bytes used to calculate partitions alignment.
# >        The default is 1MiB and it's strongly recommended to use the default.
# >        Do not modify this variable if you're not sure.
#
# The default is *not* 1MiB and will break the generation of images if it tries
# to align a small partition at the very end of the disk, when the disk is sized
# just right to fit.
#
# This is what this test validates.
diskImage.makeMBR {
  name = "diskimage";
  diskID = "012345678";
  partitions = [
    (makeNull (size.MiB 3))
    (makeNull (size.MiB 1))
  ];
}
