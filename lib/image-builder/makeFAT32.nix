{ makeFilesystem, dosfstools, mtools, libfaketime }:

/*  */ let scope = { "fileSystem.makeFAT32" =

{ partitionID, ... } @ args:
makeFilesystem (args // {
  # FAT32 can be used for ESP. Let's make this obvious.
  filesystemType = if args ? filesystemType then args.filesystemType else "FAT32";

  nativeBuildInputs = [
    libfaketime
    dosfstools
    mtools
  ];

  filesystemPhase = ''
    faketime "1970-01-01 00:00:00" mkfs.vfat \
      -F 32 \
      -i $partitionID \
      -n $partName \
      "$img"
  '';

  copyPhase = ''
    for f in ./* ./.*; do
      if [[ "$f" != "./." && "$f" != "./.." ]]; then
        faketime "1970-01-01 00:00:00" \
          mcopy -psv -i "$img" "$f" ::
      fi
    done
  '';

  checkPhase = ''
    # Always verify FS
    fsck.vfat -vn "$img"
  '';
})

/*  */ ;}; in scope."fileSystem.makeFAT32"
