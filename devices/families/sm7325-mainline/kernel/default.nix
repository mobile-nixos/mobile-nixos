{
  mobile-nixos,
  fetchFromGitHub,
  ...
}:

# SC7280 is a compute variant of the SM7325
mobile-nixos.kernel-builder {
  version = "6.15.0";
  configfile = ./config.aarch64;

  src = fetchFromGitHub {
    owner = "sc7280-mainline";
    repo = "linux";
    rev = "fc7454ac825ba92e59c202fd32944646cf87c7bc";
    hash = "sha256-P+B8ln0enxAs1m6GdMnFFDnzWad+UiNPf3uAcl0/1Dk=";
  };

  patches = [
    ./nothing-spacewar-audio.patch
  ];

  isModular = true;
  isCompressed = "gz";
}
