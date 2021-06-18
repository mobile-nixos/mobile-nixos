{ lib, imageBuilder, libfaketime, btrfs-progs }:

/*  */ let scope = { "fileSystem.makeBtrfs" =

{ partitionID, ... }@args:
imageBuilder.makeFilesystem (args // {
  filesystemType = "btrfs";
  blockSize = 4096; # dummy
  nativeBuildInputs = [btrfs-progs];
  copyPhase = ''
    mkfs.btrfs \
      -r . \
      -L "$partName" \
      -U "$partitionID" \
      --shrink \
      "$img"
  '';
})

/*  */ ;}; in scope."fileSystem.makeBtrfs"
