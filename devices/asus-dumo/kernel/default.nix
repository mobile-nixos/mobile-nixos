{
  mobile-nixos
, fetchFromGitHub
, fetchgit
, kernelPatches ? [] # FIXME
}:

(mobile-nixos.kernel-builder {
  version = "5.5.0";
  configfile = ./config.aarch64;

  hasDTB = true;

  src = fetchFromGitHub {
    owner = "torvalds";
    repo = "linux";
    rev = "v5.5";
    sha256 = "0d35pdi1mjl4rj79da5fr21jhwrx742xf8a45mkx3dlg7cbn4gnk";
  };

  patches = [
    ./0001-gru-Force-hs200-for-eMMC.patch
  ];

  isModular = false;
})
