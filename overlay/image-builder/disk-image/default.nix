{
  # Note: No `filesystem` modules are to be added here. Filesystems are used as
  #       submodules in the partitions options.
  imports = [
    ../helpers.nix
    ./basic.nix
    ./partitioning-scheme
    ./partitions.nix
  ];
}
