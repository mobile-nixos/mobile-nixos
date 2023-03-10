{ mobile-nixos
, fetchFromGitHub
, fetchFromGitLab
, ...
}:

mobile-nixos.kernel-builder rec {
  version = "6.2.0";
  configfile = ./config.aarch64;

  src = fetchFromGitLab {
    owner = "sdm845-mainline";
    repo = "linux";
    rev = "sdm845-${version}";
    hash = "sha256-UaCBjFG0TuyZhISO6H6T0oNiBft6rYJGVHZnQgal+HQ=";
  };

  isModular = false;
  isCompressed = "gz";
}
