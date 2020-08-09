{
  mobile-nixos
, fetchFromGitHub
, fetchgit
, kernelPatches ? [] # FIXME
}:

(mobile-nixos.kernel-builder {
  version = "5.8.0";
  configfile = ./config.aarch64;

  hasDTB = true;

  src = fetchFromGitHub {
    owner = "torvalds";
    repo = "linux";
    rev = "v5.8";
    sha256 = "1jffq83jzcvkvpf6afhwkaj0zlb293vlndp1r66xzx41mbnnra0x";
  };

  patches = [
    ./0001-gru-Force-hs200-for-eMMC.patch

    # Work around Regression from https://lore.kernel.org/patchwork/project/lkml/list/?series=443749
    ./0001-HACK-haphazard-revert-of-sbs-battery-improvements.patch
  ];

  isModular = false;
})
