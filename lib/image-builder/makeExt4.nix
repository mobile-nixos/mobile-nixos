{ imageBuilder, libfaketime, e2fsprogs, make_ext4fs }:

/*  */ let scope = { "fileSystem.makeExt4" =

let
  inherit (imageBuilder) makeFilesystem;
in
{ partitionID
, blockSize ? imageBuilder.size.KiB 4
, ... } @ args:
makeFilesystem (args // {
  filesystemType = "ext4";

  inherit blockSize;
  minimumSize = imageBuilder.size.MiB 5;

  nativeBuildInputs = [
    e2fsprogs
    make_ext4fs
    libfaketime
  ];

  filesystemPhase = ''
    :
  '';

  copyPhase = ''
    faketime -f "1970-01-01 00:00:00" \
      make_ext4fs \
      -b $blockSize \
      -L $partName \
      -l $size \
      -U $partitionID \
      "$img" \
      .
  '';

  checkPhase = ''
    EXT2FS_NO_MTAB_OK=yes fsck.ext4 -n -f $img
  '';
})

/*  */ ;}; in scope."fileSystem.makeExt4"
