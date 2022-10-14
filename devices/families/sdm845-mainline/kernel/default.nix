{ mobile-nixos
, fetchFromGitHub
, fetchFromGitLab
, ...
}:

mobile-nixos.kernel-builder rec {
  version = "6.0.0";
  configfile = ./config.aarch64;

  src = fetchFromGitLab {
    owner = "sdm845-mainline";
    repo = "linux";
    rev = "75140992e4ca2064f4ae75d428fa29f8ee705fba"; # sdm845/6.0-release
    hash = "sha256-lEzN31cPYJ2REmhfWkWk3wu+i0YDv9mFbjJ7sNzeTqE=";
  };

  isModular = false;
  isCompressed = "gz";
}
