{ makeFilesystem, libfaketime, size
, e2fsprogs, make_ext4fs, lkl
}:

/*  */ let scope = { "fileSystem.makeExt4" =

{ partitionID, ... } @ args:
makeFilesystem (args // {
  filesystemType = "ext4";

  minimumSize = size.MiB 5;

  nativeBuildInputs = [
    e2fsprogs
    make_ext4fs
    libfaketime
  ];

  filesystemPhase = ''
    :
  '';

  copyPhase = ''
    faketime "1970-01-01 00:00:00" \
      make_ext4fs \
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
