{ mobile-nixos
, fetchFromGitHub
, ...
}:

let
  src = fetchFromGitHub {
    owner = "msm8916-mainline";
    repo = "linux";
    rev = "40117b1fe791a88a8a5134a7f904f7d0b16caff1";     # wip/msm8916/6.19 2026/2/9
    hash = "sha256-ECCzdd8p7X2YPEaWJtTDD6fI2tw3g8Ui7vHZoh9C1BU=";
  };
in
mobile-nixos.kernel-builder {
  version = "6.19.0";
  configfile = ./config.aarch64;

  inherit src;

  patches = [
    ./pstore-and-simplefb-harpia.patch
  ];
  isModular = true;
}
