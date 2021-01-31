{
  mobile-nixos
, fetchFromGitHub
, fetchgit
}:

mobile-nixos.kernel-builder {
  version = "5.10.0";
  configfile = ./config.aarch64;

  src = fetchFromGitHub {
    owner = "torvalds";
    repo = "linux";
    rev = "v5.10";
    sha256 = "1znxp4v7ykfz4fghzjzhd5mj9pj5qpk88n7k7nbkr5x2n0xqfj6k";
  };

  patches = [
    ./0001-gru-Force-hs200-for-eMMC.patch
  ];

  isModular = false;
  isCompressed = false;
}
