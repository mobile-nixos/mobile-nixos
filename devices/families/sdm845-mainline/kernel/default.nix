{ mobile-nixos
, fetchFromGitHub
, fetchFromGitLab
, ...
}:

mobile-nixos.kernel-builder rec {
  version = "5.19.12";
  configfile = ./config.aarch64;

  src = fetchFromGitLab {
    owner = "sdm845-mainline";
    repo = "linux";
    rev = "c19a1c06f1ff61f5d6971757442acf0736585551"; # sdm845/5.19-release
    hash = "sha256-rXLNVuBR3eY4VJKYwtHYUQTX/pejgFPqWoXr/JqcLqU=";
  };

  isModular = false;
  isCompressed = "gz";
}
