{
  mobile-nixos
, fetchFromGitHub
, fetchgit
, kernelPatches ? [] # FIXME
}:

(mobile-nixos.kernel-builder {
  version = "5.7.0";
  configfile = ./config.aarch64;

  hasDTB = true;

  src = fetchFromGitHub {
    owner = "torvalds";
    repo = "linux";
    rev = "v5.7";
    sha256 = "1z91r21gp9nnw2wr552xrrpm2gshq3vsdd9wj12pzhf7053wdcid";
  };

  patches = [
    ./0001-gru-Force-hs200-for-eMMC.patch
  ];

  isModular = false;
})
