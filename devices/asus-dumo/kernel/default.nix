{
  mobile-nixos
, fetchFromGitHub
, fetchgit
, kernelPatches ? [] # FIXME
}:

(mobile-nixos.kernel-builder {
  version = "5.3.0";
  configfile = ./config.aarch64;

  hasDTB = true;

  src = fetchFromGitHub {
    owner = "torvalds";
    repo = "linux";
    rev = "v5.3";
    sha256 = "1iiv8fim1l4n7n7wkq0x4bf84ygrd1i7zaybmsphswsx1cpb5g6j";
  };

  patches = [
    ./0001-HACK-disables-hs400es-codepath.patch
  ];

  isModular = false;
})
