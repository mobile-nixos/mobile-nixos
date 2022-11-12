{
  mobile-nixos
, fetchFromGitHub
, fetchpatch
, ...
}:

let
  sdrPatch = rev: sha256: fetchpatch {
    url = "https://github.com/samueldr/linux/commit/${rev}.patch";
    inherit sha256;
  };
in
mobile-nixos.kernel-builder {
  version = "6.0.0";
  configfile = ./config.aarch64;

  src = fetchFromGitHub {
    owner = "torvalds";
    repo = "linux";
    rev = "v6.0";
    sha256 = "sha256-uHNlzGr5NqrvLSRX2hK0kwI0DvvkrbcCNIOg8ro3+94=";
  };

  patches = [
  ];

  isModular = false;
  isCompressed = false;
}
