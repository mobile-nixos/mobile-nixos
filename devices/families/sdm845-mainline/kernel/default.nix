{ mobile-nixos
, fetchFromGitHub
, fetchFromGitLab
, ...
}:

mobile-nixos.kernel-builder rec {
  version = "5.19.16";
  configfile = ./config.aarch64;

  src = fetchFromGitLab {
    owner = "sdm845-mainline";
    repo = "linux";
    rev = "9aa25bf492928bc7a4542e87d28919c9ac36d27c"; # sdm845/5.19-release
    hash = "sha256-f9eSZbP9Dx369MFRPBUIjCkILlHrkAaMa1hEK+nvK0Q=";
  };

  isModular = false;
  isCompressed = "gz";
}
