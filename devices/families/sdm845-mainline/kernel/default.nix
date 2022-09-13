{ mobile-nixos
, fetchFromGitHub
, fetchFromGitLab
, ...
}:

mobile-nixos.kernel-builder rec {
  version = "5.19.7";
  configfile = ./config.aarch64;

  src = fetchFromGitLab {
    owner = "sdm845-mainline";
    repo = "linux";
    rev = "3c3bb6290821d2feb6adb017227dde0ce773bd16"; # sdm845/5.19-release
    hash = "sha256-1kHco5IRDEFruiZuplug5AZbApUQPV780xFM8PYK02I=";
  };

  isModular = false;
  isCompressed = "gz";
}
